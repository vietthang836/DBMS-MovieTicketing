-- ============================================================
-- KHỞI TẠO CSDL CHUẨN HÓA: CinemaBooking (CHƯƠNG 3 & CHƯƠNG 4)
-- ============================================================
USE master;
GO

IF DB_ID(N'CinemaBooking') IS NULL
BEGIN
    CREATE DATABASE CinemaBooking;
END
GO

USE CinemaBooking;
GO

-- 1. Xóa bảng cũ theo thứ tự con -> cha để chạy lại sạch sẽ
DROP TABLE IF EXISTS dbo.ThanhToan;
DROP TABLE IF EXISTS dbo.ChiTietDatVe;
DROP TABLE IF EXISTS dbo.Ghe_SuatChieu;
DROP TABLE IF EXISTS dbo.GiaoDich_DatVe;
DROP TABLE IF EXISTS dbo.SuatChieu;
DROP TABLE IF EXISTS dbo.Ghe;
DROP TABLE IF EXISTS dbo.PhongChieu;
DROP TABLE IF EXISTS dbo.Phim;
DROP TABLE IF EXISTS dbo.NguoiDung;
GO

-- 2. Tạo các bảng Danh mục
CREATE TABLE dbo.NguoiDung (
    MaND INT IDENTITY(1,1) PRIMARY KEY,
    TenND NVARCHAR(100) NOT NULL,
    TaiKhoan VARCHAR(50) NOT NULL UNIQUE,
    MatKhau VARCHAR(255) NOT NULL,
    Email VARCHAR(100) NULL,
    SoDienThoai VARCHAR(15) NULL
);

CREATE TABLE dbo.Phim (
    MaPhim INT IDENTITY(1,1) PRIMARY KEY,
    TenPhim NVARCHAR(200) NOT NULL,
    ThoiLuong INT NOT NULL CHECK (ThoiLuong > 0),
    DaoDien NVARCHAR(100) NULL,
    TheLoai NVARCHAR(100) NULL
);

CREATE TABLE dbo.PhongChieu (
    MaPhong INT IDENTITY(1,1) PRIMARY KEY,
    TenPhong NVARCHAR(50) NOT NULL,
    TongSoGhe INT NOT NULL CHECK (TongSoGhe > 0)
);

CREATE TABLE dbo.Ghe (
    MaGhe INT IDENTITY(1,1) PRIMARY KEY,
    MaPhong INT NOT NULL FOREIGN KEY REFERENCES dbo.PhongChieu(MaPhong),
    TenGhe VARCHAR(10) NOT NULL, -- VD: H1, H2, H3
    LoaiGhe NVARCHAR(30) NOT NULL DEFAULT N'Standard',
    CONSTRAINT UQ_Ghe_Phong_Ten UNIQUE (MaPhong, TenGhe)
);

CREATE TABLE dbo.SuatChieu (
    MaSC INT IDENTITY(1,1) PRIMARY KEY,
    MaPhim INT NOT NULL FOREIGN KEY REFERENCES dbo.Phim(MaPhim),
    MaPhong INT NOT NULL FOREIGN KEY REFERENCES dbo.PhongChieu(MaPhong),
    ThoiGianChieu DATETIME2(0) NOT NULL,
    GiaVe DECIMAL(12,2) NOT NULL CHECK (GiaVe >= 0)
);

-- 3. Tạo các bảng Giao dịch & Trạng thái ghế cốt lõi
CREATE TABLE dbo.GiaoDich_DatVe (
    MaGD BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaND INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung(MaND),
    NgayDat DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    TongTien DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (TongTien >= 0),
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Pending'
        CHECK (TrangThai IN (N'Pending', N'Success', N'Failed', N'Rollback'))
);

CREATE TABLE dbo.Ghe_SuatChieu (
    MaGhe INT NOT NULL FOREIGN KEY REFERENCES dbo.Ghe(MaGhe),
    MaSC INT NOT NULL FOREIGN KEY REFERENCES dbo.SuatChieu(MaSC),
    TrangThai TINYINT NOT NULL DEFAULT 0 CHECK (TrangThai IN (0, 1, 2)), -- 0: Trống, 1: Giữ, 2: Bán
    Version INT NOT NULL DEFAULT 1, -- Dùng INT để tăng tự động +1 khi cập nhật (Optimistic Locking)
    MaGD BIGINT NULL FOREIGN KEY REFERENCES dbo.GiaoDich_DatVe(MaGD),
    ThoiGianHetHan DATETIME2(0) NULL,
    CONSTRAINT PK_Ghe_SuatChieu PRIMARY KEY (MaGhe, MaSC)
);

CREATE TABLE dbo.ChiTietDatVe (
    MaGD BIGINT NOT NULL FOREIGN KEY REFERENCES dbo.GiaoDich_DatVe(MaGD),
    MaGhe INT NOT NULL,
    MaSC INT NOT NULL,
    GiaVe DECIMAL(12,2) NOT NULL CHECK (GiaVe >= 0),
    CONSTRAINT PK_ChiTietDatVe PRIMARY KEY (MaGD, MaGhe, MaSC),
    CONSTRAINT FK_ChiTiet_GheSuatChieu FOREIGN KEY (MaGhe, MaSC) REFERENCES dbo.Ghe_SuatChieu(MaGhe, MaSC)
);

CREATE TABLE dbo.ThanhToan (
    MaThanhToan BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaGD BIGINT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.GiaoDich_DatVe(MaGD),
    PhuongThuc NVARCHAR(50) NOT NULL,
    SoTien DECIMAL(12,2) NOT NULL CHECK (SoTien >= 0),
    ThoiGianTT DATETIME2(0) NULL,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Pending' CHECK (TrangThai IN (N'Pending', N'Success', N'Failed')),
    MaGiaoDichNganHang VARCHAR(100) NULL
);
GO

-- 4. Thêm dữ liệu mẫu để test (Seed Data)
INSERT INTO dbo.NguoiDung (TenND, TaiKhoan, MatKhau, Email, SoDienThoai) VALUES 
(N'Khách Hàng A', 'userA', '123456', 'userA@gmail.com', '0901111111'),
(N'Khách Hàng B', 'userB', '123456', 'userB@gmail.com', '0902222222');

INSERT INTO dbo.Phim (TenPhim, ThoiLuong, DaoDien, TheLoai) VALUES 
(N'Avatar 3', 180, N'James Cameron', N'Hành động');

INSERT INTO dbo.PhongChieu (TenPhong, TongSoGhe) VALUES (N'Phòng 01', 50);

INSERT INTO dbo.Ghe (MaPhong, TenGhe, LoaiGhe) VALUES 
(1, 'H1', N'VIP'), (1, 'H2', N'VIP'), (1, 'H3', N'VIP');

INSERT INTO dbo.SuatChieu (MaPhim, MaPhong, ThoiGianChieu, GiaVe) VALUES 
(1, 1, '2026-12-01 19:00:00', 100000);

INSERT INTO dbo.Ghe_SuatChieu (MaGhe, MaSC, TrangThai, Version) VALUES 
(1, 1, 0, 1), -- Ghế H1 (MaGhe = 1)
(2, 1, 0, 1), -- Ghế H2 (MaGhe = 2)
(3, 1, 0, 1); -- Ghế H3 (MaGhe = 3)
GO

-- 5. Stored Procedure: Khóa Lạc Quan (Optimistic Locking) giữ ghế 5 phút
CREATE OR ALTER PROCEDURE dbo.sp_GiuGhe_LacQuan
    @MaGhe INT,
    @MaSC INT,
    @MaND INT,
    @VersionCu INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra ghế còn trống và đúng Version đang hiển thị trên màn hình khách
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Ghe_SuatChieu
            WHERE MaGhe = @MaGhe AND MaSC = @MaSC AND TrangThai = 0 AND Version = @VersionCu
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT N'THẤT BẠI: Ghế đã có người khác giữ hoặc Version đã thay đổi!' AS ThongBao;
            RETURN;
        END

        -- Tạo giao dịch đặt vé mới (Pending)
        DECLARE @GiaVe DECIMAL(12,2) = (SELECT GiaVe FROM dbo.SuatChieu WHERE MaSC = @MaSC);
        INSERT INTO dbo.GiaoDich_DatVe (MaND, TongTien, TrangThai) VALUES (@MaND, @GiaVe, N'Pending');
        DECLARE @MaGD BIGINT = SCOPE_IDENTITY();

        -- Cập nhật trạng thái ghế sang Đang giữ (1) và tăng Version
        UPDATE dbo.Ghe_SuatChieu
        SET TrangThai = 1,
            MaGD = @MaGD,
            ThoiGianHetHan = DATEADD(MINUTE, 5, SYSDATETIME()),
            Version = Version + 1
        WHERE MaGhe = @MaGhe AND MaSC = @MaSC AND TrangThai = 0 AND Version = @VersionCu;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT N'THẤT BẠI: Xung đột cập nhật đồng thời (Lost Update prevented)!' AS ThongBao;
            RETURN;
        END

        INSERT INTO dbo.ChiTietDatVe (MaGD, MaGhe, MaSC, GiaVe) VALUES (@MaGD, @MaGhe, @MaSC, @GiaVe);

        COMMIT TRANSACTION;
        SELECT N'THÀNH CÔNG: Giữ ghế trong 5 phút!' AS ThongBao, @MaGD AS MaGiaoDich;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS Loi;
    END CATCH
END;
GO