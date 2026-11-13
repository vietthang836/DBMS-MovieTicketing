USE CinemaBooking;
GO

-- ============================================================
-- 1. TRIGGER TOÀN VẸN: Kiểm soát tổng số ghế không vượt sức chứa phòng (WBS 3.1)
-- ============================================================
CREATE OR ALTER TRIGGER dbo.trg_KiemTraTongSoGhe
ON dbo.Ghe
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM dbo.PhongChieu p
        JOIN (SELECT DISTINCT MaPhong FROM inserted) i ON p.MaPhong = i.MaPhong
        WHERE (SELECT COUNT(*) FROM dbo.Ghe g WHERE g.MaPhong = p.MaPhong) > p.TongSoGhe
    )
    BEGIN
        RAISERROR(N'LỖI TOÀN VẸN: Số lượng ghế tạo ra vượt quá Tổng số ghế quy định của phòng chiếu!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- ============================================================
-- 2. STORED PROCEDURE: Thanh toán hoặc Rollback giao dịch (Chương 2 & 4)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_XuLyThanhToan
    @MaGD BIGINT,
    @PhuongThuc NVARCHAR(50),
    @ThanhToanThanhCong BIT -- 1: Thành công, 0: Thất bại
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra giao dịch có đang ở trạng thái Pending và chưa quá hạn 5 phút không
        IF NOT EXISTS (
            SELECT 1 FROM dbo.GiaoDich_DatVe 
            WHERE MaGD = @MaGD AND TrangThai = N'Pending'
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT N'THẤT BẠI: Giao dịch không tồn tại hoặc đã được xử lý trước đó!' AS ThongBao;
            RETURN;
        END

        -- Kiểm tra xem ghế thuộc giao dịch này có bị hết hạn 5 phút chưa
        IF EXISTS (
            SELECT 1 FROM dbo.Ghe_SuatChieu 
            WHERE MaGD = @MaGD AND (TrangThai <> 1 OR ThoiGianHetHan < SYSDATETIME())
        )
        BEGIN
            -- Hết hạn -> Hủy giao dịch và trả ghế về Trống (0)
            UPDATE dbo.GiaoDich_DatVe SET TrangThai = N'Failed' WHERE MaGD = @MaGD;
            UPDATE dbo.Ghe_SuatChieu 
            SET TrangThai = 0, MaGD = NULL, ThoiGianHetHan = NULL, Version = Version + 1
            WHERE MaGD = @MaGD;

            COMMIT TRANSACTION;
            SELECT N'HẾT HẠN: Đã quá 5 phút giữ chỗ, ghế đã tự động trả về trạng thái Trống!' AS ThongBao;
            RETURN;
        END

        DECLARE @TongTien DECIMAL(12,2) = (SELECT TongTien FROM dbo.GiaoDich_DatVe WHERE MaGD = @MaGD);

        IF @ThanhToanThanhCong = 1
        BEGIN
            -- Thanh toán thành công -> Ghế chuyển sang Đã bán (2), xóa ThoiGianHetHan
            UPDATE dbo.GiaoDich_DatVe SET TrangThai = N'Success' WHERE MaGD = @MaGD;
            
            UPDATE dbo.Ghe_SuatChieu 
            SET TrangThai = 2, ThoiGianHetHan = NULL, Version = Version + 1
            WHERE MaGD = @MaGD;

            INSERT INTO dbo.ThanhToan (MaGD, PhuongThuc, SoTien, ThoiGianTT, TrangThai, MaGiaoDichNganHang)
            VALUES (@MaGD, @PhuongThuc, @TongTien, SYSDATETIME(), N'Success', 'TXN_' + CAST(@MaGD AS VARCHAR));

            COMMIT TRANSACTION;
            SELECT N'THÀNH CÔNG: Thanh toán hoàn tất, vé đã được xuất!' AS ThongBao;
        END
        ELSE
        BEGIN
            -- Thanh toán thất bại -> Rollback trả ghế về Trống (0) tránh ghế lấp lửng
            UPDATE dbo.GiaoDich_DatVe SET TrangThai = N'Rollback' WHERE MaGD = @MaGD;

            UPDATE dbo.Ghe_SuatChieu 
            SET TrangThai = 0, MaGD = NULL, ThoiGianHetHan = NULL, Version = Version + 1
            WHERE MaGD = @MaGD;

            INSERT INTO dbo.ThanhToan (MaGD, PhuongThuc, SoTien, ThoiGianTT, TrangThai)
            VALUES (@MaGD, @PhuongThuc, @TongTien, SYSDATETIME(), N'Failed');

            COMMIT TRANSACTION;
            SELECT N'THANH TOÁN THẤT BẠI: Đã hoàn tác giao dịch và trả ghế về Trống!' AS ThongBao;
        END
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS Loi;
    END CATCH
END;
GO

-- ============================================================
-- 3. KHÓA BI QUAN (UPDLOCK) + LOCK ORDERING CHỐNG DEADLOCK (WBS 3.2 & 3.4)
-- Đặt nhiều ghế cùng lúc (VD: '3,2' -> tự động sắp xếp thành 2 rồi 3 trước khi khóa)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GiuNhieuGhe_BiQuan_ChongDeadlock
    @DanhSachMaGhe VARCHAR(100), -- Truyền chuỗi ID ghế cách nhau dấu phẩy, VD: '3,2'
    @MaSC INT,
    @MaND INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- BƯỚC QUAN TRỌNG (LOCK ORDERING): Tách chuỗi và sắp xếp MaGhe TĂNG DẦN để chống Deadlock
        DECLARE @BangGheCanDat TABLE (MaGhe INT PRIMARY KEY);
        INSERT INTO @BangGheCanDat (MaGhe)
        SELECT DISTINCT CAST(TRIM(value) AS INT)
        FROM STRING_SPLIT(@DanhSachMaGhe, ',')
        WHERE TRIM(value) <> '';

        DECLARE @TongGheYeuCau INT = (SELECT COUNT(*) FROM @BangGheCanDat);

        -- Khóa bi quan (UPDLOCK, ROWLOCK) theo đúng thứ tự MaGhe tăng dần
        DECLARE @SoGheTrong INT;
        SELECT @SoGheTrong = COUNT(*)
        FROM dbo.Ghe_SuatChieu g WITH (UPDLOCK, ROWLOCK)
        JOIN @BangGheCanDat b ON g.MaGhe = b.MaGhe
        WHERE g.MaSC = @MaSC 
          AND (g.TrangThai = 0 OR (g.TrangThai = 1 AND g.ThoiGianHetHan < SYSDATETIME()));

        -- Tính nguyên tử (Atomicity): Chỉ giữ khi TẤT CẢ ghế khách chọn đều trống
        IF @SoGheTrong < @TongGheYeuCau
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT N'THẤT BẠI: Một hoặc nhiều ghế trong danh sách đã có người giữ/mua!' AS ThongBao;
            RETURN;
        END

        -- Tạo giao dịch đặt nhiều ghế
        DECLARE @GiaVe DECIMAL(12,2) = (SELECT GiaVe FROM dbo.SuatChieu WHERE MaSC = @MaSC);
        INSERT INTO dbo.GiaoDich_DatVe (MaND, TongTien, TrangThai) 
        VALUES (@MaND, @GiaVe * @TongGheYeuCau, N'Pending');
        DECLARE @MaGD BIGINT = SCOPE_IDENTITY();

        -- Cập nhật toàn bộ ghế sang Đang giữ (1)
        UPDATE g
        SET g.TrangThai = 1,
            g.MaGD = @MaGD,
            g.ThoiGianHetHan = DATEADD(MINUTE, 5, SYSDATETIME()),
            g.Version = g.Version + 1
        FROM dbo.Ghe_SuatChieu g
        JOIN @BangGheCanDat b ON g.MaGhe = b.MaGhe
        WHERE g.MaSC = @MaSC;

        INSERT INTO dbo.ChiTietDatVe (MaGD, MaGhe, MaSC, GiaVe)
        SELECT @MaGD, b.MaGhe, @MaSC, @GiaVe FROM @BangGheCanDat b;

        -- Giả lập độ trễ 5 giây để dễ test tranh chấp khóa bi quan trên 2 tab SSMS
        WAITFOR DELAY '00:00:05';

        COMMIT TRANSACTION;
        SELECT N'THÀNH CÔNG (UPDLOCK + Lock Ordering): Đã giữ toàn bộ ghế!' AS ThongBao, @MaGD AS MaGiaoDich;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ChiTietLoi;
    END CATCH
END;
GO