-- =====================================================
-- CHƯƠNG 4: XÂY DỰNG VÀ TRIỂN KHAI HỆ THỐNG XỬ LÝ XUNG ĐỘT 
-- SQL SERVER - TAO CO SO DU LIEU VA 9 BANG
-- =====================================================

-- 1. TAO DATABASE NEU CHUA TON TAI
USE master;
GO

IF DB_ID(N'CinemaBooking') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE CinemaBooking');
END;
GO

USE CinemaBooking;
GO

-- =====================================================
-- 2. XOA CAC BANG CU NEU DA TON TAI
-- XOA BANG CON TRUOC, BANG CHA SAU
-- =====================================================

IF OBJECT_ID(N'dbo.ThanhToan', N'U') IS NOT NULL
    DROP TABLE dbo.ThanhToan;

IF OBJECT_ID(N'dbo.ChiTietDatVe', N'U') IS NOT NULL
    DROP TABLE dbo.ChiTietDatVe;

IF OBJECT_ID(N'dbo.Ghe_SuatChieu', N'U') IS NOT NULL
    DROP TABLE dbo.Ghe_SuatChieu;

IF OBJECT_ID(N'dbo.GiaoDich_DatVe', N'U') IS NOT NULL
    DROP TABLE dbo.GiaoDich_DatVe;

IF OBJECT_ID(N'dbo.SuatChieu', N'U') IS NOT NULL
    DROP TABLE dbo.SuatChieu;

IF OBJECT_ID(N'dbo.Ghe', N'U') IS NOT NULL
    DROP TABLE dbo.Ghe;

IF OBJECT_ID(N'dbo.PhongChieu', N'U') IS NOT NULL
    DROP TABLE dbo.PhongChieu;

IF OBJECT_ID(N'dbo.Phim', N'U') IS NOT NULL
    DROP TABLE dbo.Phim;

IF OBJECT_ID(N'dbo.NguoiDung', N'U') IS NOT NULL
    DROP TABLE dbo.NguoiDung;
GO

-- =====================================================
-- 3. BANG NGUOI DUNG
-- =====================================================

CREATE TABLE dbo.NguoiDung
(
    MaND INT IDENTITY(1,1) NOT NULL,
    TenND NVARCHAR(100) NOT NULL,
    TaiKhoan VARCHAR(50) NOT NULL,
    MatKhau VARCHAR(255) NOT NULL,
    Email VARCHAR(100) NULL,
    SoDienThoai VARCHAR(15) NULL,

    CONSTRAINT PK_NguoiDung
        PRIMARY KEY (MaND),

    CONSTRAINT UQ_NguoiDung_TaiKhoan
        UNIQUE (TaiKhoan)
);
GO

-- =====================================================
-- 4. BANG PHIM
-- =====================================================

CREATE TABLE dbo.Phim
(
    MaPhim INT IDENTITY(1,1) NOT NULL,
    TenPhim NVARCHAR(200) NOT NULL,
    ThoiLuong INT NOT NULL,
    DaoDien NVARCHAR(100) NULL,
    TheLoai NVARCHAR(100) NULL,

    CONSTRAINT PK_Phim
        PRIMARY KEY (MaPhim),

    CONSTRAINT CK_Phim_ThoiLuong
        CHECK (ThoiLuong > 0)
);
GO

-- =====================================================
-- 5. BANG PHONG CHIEU
-- =====================================================

CREATE TABLE dbo.PhongChieu
(
    MaPhong INT IDENTITY(1,1) NOT NULL,
    TenPhong NVARCHAR(50) NOT NULL,
    TongSoGhe INT NOT NULL,

    CONSTRAINT PK_PhongChieu
        PRIMARY KEY (MaPhong),

    CONSTRAINT CK_PhongChieu_TongSoGhe
        CHECK (TongSoGhe > 0)
);
GO

-- =====================================================
-- 6. BANG GHE
-- =====================================================

CREATE TABLE dbo.Ghe
(
    MaGhe INT IDENTITY(1,1) NOT NULL,
    MaPhong INT NOT NULL,
    TenGhe VARCHAR(10) NOT NULL,
    LoaiGhe NVARCHAR(30) NOT NULL,

    CONSTRAINT PK_Ghe
        PRIMARY KEY (MaGhe),

    CONSTRAINT FK_Ghe_PhongChieu
        FOREIGN KEY (MaPhong)
        REFERENCES dbo.PhongChieu(MaPhong),

    CONSTRAINT UQ_Ghe_Phong_Ten
        UNIQUE (MaPhong, TenGhe)
);
GO

-- =====================================================
-- 7. BANG SUAT CHIEU
-- =====================================================

CREATE TABLE dbo.SuatChieu
(
    MaSC INT IDENTITY(1,1) NOT NULL,
    MaPhim INT NOT NULL,
    MaPhong INT NOT NULL,
    ThoiGianChieu DATETIME2(0) NOT NULL,
    GiaVe DECIMAL(12,2) NOT NULL,

    CONSTRAINT PK_SuatChieu
        PRIMARY KEY (MaSC),

    CONSTRAINT FK_SuatChieu_Phim
        FOREIGN KEY (MaPhim)
        REFERENCES dbo.Phim(MaPhim),

    CONSTRAINT FK_SuatChieu_Phong
        FOREIGN KEY (MaPhong)
        REFERENCES dbo.PhongChieu(MaPhong),

    CONSTRAINT CK_SuatChieu_GiaVe
        CHECK (GiaVe >= 0)
);
GO

-- =====================================================
-- 8. BANG GIAO DICH DAT VE
-- =====================================================

CREATE TABLE dbo.GiaoDich_DatVe
(
    MaGD BIGINT IDENTITY(1,1) NOT NULL,
    MaND INT NOT NULL,
    NgayDat DATETIME2(0) NOT NULL
        DEFAULT SYSDATETIME(),
    TongTien DECIMAL(12,2) NOT NULL
        DEFAULT 0,
    TrangThai NVARCHAR(20) NOT NULL
        DEFAULT N'Pending',

    CONSTRAINT PK_GiaoDich_DatVe
        PRIMARY KEY (MaGD),

    CONSTRAINT FK_GiaoDich_NguoiDung
        FOREIGN KEY (MaND)
        REFERENCES dbo.NguoiDung(MaND),

    CONSTRAINT CK_GiaoDich_TongTien
        CHECK (TongTien >= 0),

    CONSTRAINT CK_GiaoDich_TrangThai
        CHECK (TrangThai IN
        (N'Pending', N'Success', N'Failed', N'Rollback'))
);
GO

-- =====================================================
-- 9. BANG GHE THEO SUAT CHIEU
--
-- TrangThai:
-- 0 = Ghe trong
-- 1 = Dang giu
-- 2 = Da ban
--
-- Version: Tu dong thay doi khi ban ghi cap nhat
-- =====================================================

CREATE TABLE dbo.Ghe_SuatChieu
(
    MaGhe INT NOT NULL,
    MaSC INT NOT NULL,
    TrangThai TINYINT NOT NULL DEFAULT 0,
    Version ROWVERSION,
    MaGD BIGINT NULL,
    ThoiGianHetHan DATETIME2(0) NULL,

    CONSTRAINT PK_Ghe_SuatChieu
        PRIMARY KEY (MaGhe, MaSC),

    CONSTRAINT FK_GheSC_Ghe
        FOREIGN KEY (MaGhe)
        REFERENCES dbo.Ghe(MaGhe),

    CONSTRAINT FK_GheSC_SuatChieu
        FOREIGN KEY (MaSC)
        REFERENCES dbo.SuatChieu(MaSC),

    CONSTRAINT FK_GheSC_GiaoDich
        FOREIGN KEY (MaGD)
        REFERENCES dbo.GiaoDich_DatVe(MaGD),

    CONSTRAINT CK_GheSC_TrangThai
        CHECK (TrangThai IN (0, 1, 2)),

    CONSTRAINT CK_GheSC_ThongTinGiuGhe
        CHECK
        (
            (TrangThai = 0
                AND MaGD IS NULL
                AND ThoiGianHetHan IS NULL)

            OR

            (TrangThai = 1
                AND MaGD IS NOT NULL
                AND ThoiGianHetHan IS NOT NULL)

            OR

            (TrangThai = 2
                AND MaGD IS NOT NULL
                AND ThoiGianHetHan IS NULL)
        )
);
GO

-- =====================================================
-- 10. BANG CHI TIET DAT VE
-- =====================================================

CREATE TABLE dbo.ChiTietDatVe
(
    MaGD BIGINT NOT NULL,
    MaGhe INT NOT NULL,
    MaSC INT NOT NULL,
    GiaVe DECIMAL(12,2) NOT NULL,

    CONSTRAINT PK_ChiTietDatVe
        PRIMARY KEY (MaGD, MaGhe, MaSC),

    CONSTRAINT FK_ChiTiet_GiaoDich
        FOREIGN KEY (MaGD)
        REFERENCES dbo.GiaoDich_DatVe(MaGD),

    CONSTRAINT FK_ChiTiet_GheSuatChieu
        FOREIGN KEY (MaGhe, MaSC)
        REFERENCES dbo.Ghe_SuatChieu(MaGhe, MaSC),

    CONSTRAINT CK_ChiTiet_GiaVe
        CHECK (GiaVe >= 0)
);
GO

-- =====================================================
-- 11. BANG THANH TOAN
-- =====================================================

CREATE TABLE dbo.ThanhToan
(
    MaThanhToan BIGINT IDENTITY(1,1) NOT NULL,
    MaGD BIGINT NOT NULL,
    PhuongThuc NVARCHAR(50) NOT NULL,
    SoTien DECIMAL(12,2) NOT NULL,
    ThoiGianTT DATETIME2(0) NULL,
    TrangThai NVARCHAR(20) NOT NULL
        DEFAULT N'Pending',
    MaGiaoDichNganHang VARCHAR(100) NULL,

    CONSTRAINT PK_ThanhToan
        PRIMARY KEY (MaThanhToan),

    CONSTRAINT UQ_ThanhToan_MaGD
        UNIQUE (MaGD),

    CONSTRAINT FK_ThanhToan_GiaoDich
        FOREIGN KEY (MaGD)
        REFERENCES dbo.GiaoDich_DatVe(MaGD),

    CONSTRAINT CK_ThanhToan_SoTien
        CHECK (SoTien >= 0),

    CONSTRAINT CK_ThanhToan_TrangThai
        CHECK (TrangThai IN
        (N'Pending', N'Success', N'Failed'))
);
GO

-- =====================================================
-- 12. TAO INDEX
-- =====================================================

CREATE INDEX IX_SuatChieu_MaPhim
ON dbo.SuatChieu(MaPhim);
GO

CREATE INDEX IX_SuatChieu_ThoiGian
ON dbo.SuatChieu(ThoiGianChieu);
GO

CREATE INDEX IX_GheSuatChieu_TrangThai
ON dbo.Ghe_SuatChieu(MaSC, TrangThai);
GO

CREATE INDEX IX_GiaoDich_MaND
ON dbo.GiaoDich_DatVe(MaND);
GO

CREATE INDEX IX_ChiTietDatVe_MaSC
ON dbo.ChiTietDatVe(MaSC);
GO

-- =====================================================
-- 13. KIEM TRA KET QUA
-- =====================================================

SELECT
    TABLE_NAME AS TenBang
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

-- KIEM TRA COT VERSION
SELECT
    COLUMN_NAME AS TenCot,
    DATA_TYPE AS KieuDuLieu
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Ghe_SuatChieu'
  AND COLUMN_NAME = 'Version';
GO
USE [sql];
GO

-- =========================================
-- 1. TAO BANG NGUOIDUNG
-- =========================================
IF OBJECT_ID('dbo.NguoiDung', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.NguoiDung
    (
        MaND INT IDENTITY(1,1) PRIMARY KEY,
        TenND NVARCHAR(100) NOT NULL,
        TaiKhoan VARCHAR(50) NOT NULL UNIQUE,
        MatKhau NVARCHAR(255) NOT NULL,
        Email VARCHAR(100),
        SoDienThoai VARCHAR(15)
    );
END;
GO

-- =========================================
-- 2. TAO BANG PHIM
-- =========================================
IF OBJECT_ID('dbo.Phim', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Phim
    (
        MaPhim INT IDENTITY(1,1) PRIMARY KEY,
        TenPhim NVARCHAR(200) NOT NULL,
        ThoiLuong INT,
        DaoDien NVARCHAR(100),
        TheLoai NVARCHAR(100)
    );
END;
GO

-- =========================================
-- 3. TAO BANG PHONGCHIEU
-- =========================================
IF OBJECT_ID('dbo.PhongChieu', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PhongChieu
    (
        MaPhong INT IDENTITY(1,1) PRIMARY KEY,
        TenPhong NVARCHAR(100) NOT NULL,
        TongSoGhe INT
    );
END;
GO

-- =========================================
-- 4. TAO BANG SUATCHIEU
-- =========================================
IF OBJECT_ID('dbo.SuatChieu', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SuatChieu
    (
        MaSC INT IDENTITY(1,1) PRIMARY KEY,
        MaPhim INT NOT NULL,
        MaPhong INT NOT NULL,
        ThoiGianChieu DATETIME2 NOT NULL,

        FOREIGN KEY (MaPhim) REFERENCES dbo.Phim(MaPhim),
        FOREIGN KEY (MaPhong) REFERENCES dbo.PhongChieu(MaPhong)
    );
END;
GO

-- =========================================
-- 5. TAO BANG GHE_SUATCHIEU
-- TrangThai: 0 = Trong, 1 = Dang giu, 2 = Da ban
-- =========================================
IF OBJECT_ID('dbo.Ghe_SuatChieu', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ghe_SuatChieu
    (
        MaGhe NVARCHAR(10) NOT NULL,
        MaSC INT NOT NULL,
        TrangThai TINYINT NOT NULL DEFAULT 0,
        Version INT NOT NULL DEFAULT 0,

        CONSTRAINT PK_Ghe_SuatChieu
            PRIMARY KEY (MaGhe, MaSC),

        CONSTRAINT FK_Ghe_SuatChieu_SuatChieu
            FOREIGN KEY (MaSC) REFERENCES dbo.SuatChieu(MaSC),

        CONSTRAINT CK_Ghe_TrangThai
            CHECK (TrangThai IN (0, 1, 2))
    );
END;
GO

-- =========================================
-- 6. TAO BANG GIAODICH_DATVE
-- =========================================
IF OBJECT_ID('dbo.GiaoDich_DatVe', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.GiaoDich_DatVe
    (
        MaGD BIGINT IDENTITY(1,1) PRIMARY KEY,
        MaND INT NOT NULL,
        NgayDat DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        TongTien DECIMAL(18,2) NOT NULL,
        HanGiuDen DATETIME2 NOT NULL,
        TrangThaiThanhToan NVARCHAR(20) NOT NULL,

        FOREIGN KEY (MaND) REFERENCES dbo.NguoiDung(MaND),

        CONSTRAINT CK_GiaoDich_TrangThai
            CHECK (TrangThaiThanhToan IN
            ('Pending', 'Success', 'Failed', 'Rollback'))
    );
END;
GO

-- =========================================
-- 7. TAO BANG CHITIETDATVE
-- =========================================
IF OBJECT_ID('dbo.ChiTietDatVe', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChiTietDatVe
    (
        MaGD BIGINT NOT NULL,
        MaGhe NVARCHAR(10) NOT NULL,
        MaSC INT NOT NULL,
        GiaVe DECIMAL(18,2) NOT NULL,

        CONSTRAINT PK_ChiTietDatVe
            PRIMARY KEY (MaGD, MaGhe, MaSC),

        FOREIGN KEY (MaGD)
            REFERENCES dbo.GiaoDich_DatVe(MaGD),

        FOREIGN KEY (MaGhe, MaSC)
            REFERENCES dbo.Ghe_SuatChieu(MaGhe, MaSC)
    );
END;
GO

-- =========================================
-- 8. THEM DU LIEU MAU
-- =========================================

IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE MaND = 1)
BEGIN
    SET IDENTITY_INSERT dbo.NguoiDung ON;

    INSERT INTO dbo.NguoiDung
        (MaND, TenND, TaiKhoan, MatKhau, Email, SoDienThoai)
    VALUES
        (1, N'Nguyen Van A', 'user01', N'123456',
         'user01@gmail.com', '0900000001');

    SET IDENTITY_INSERT dbo.NguoiDung OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Phim WHERE MaPhim = 1)
BEGIN
    SET IDENTITY_INSERT dbo.Phim ON;

    INSERT INTO dbo.Phim
        (MaPhim, TenPhim, ThoiLuong, DaoDien, TheLoai)
    VALUES
        (1, N'Phim thu nghiem', 120, N'Dao dien A', N'Hanh dong');

    SET IDENTITY_INSERT dbo.Phim OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.PhongChieu WHERE MaPhong = 1)
BEGIN
    SET IDENTITY_INSERT dbo.PhongChieu ON;

    INSERT INTO dbo.PhongChieu
        (MaPhong, TenPhong, TongSoGhe)
    VALUES
        (1, N'Phong 1', 50);

    SET IDENTITY_INSERT dbo.PhongChieu OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.SuatChieu WHERE MaSC = 1)
BEGIN
    SET IDENTITY_INSERT dbo.SuatChieu ON;

    INSERT INTO dbo.SuatChieu
        (MaSC, MaPhim, MaPhong, ThoiGianChieu)
    VALUES
        (1, 1, 1, DATEADD(DAY, 1, SYSDATETIME()));

    SET IDENTITY_INSERT dbo.SuatChieu OFF;
END;

IF NOT EXISTS (
    SELECT 1 FROM dbo.Ghe_SuatChieu
    WHERE MaGhe = N'H1' AND MaSC = 1
)
BEGIN
    INSERT INTO dbo.Ghe_SuatChieu (MaGhe, MaSC, TrangThai, Version)
    VALUES
        (N'H1', 1, 0, 0),
        (N'H2', 1, 0, 0);
END;
GO



-- ==========================================
-- 1. TAO BANG GHE_SUATCHIEU 
-- ==========================================

IF OBJECT_ID('dbo.Ghe_SuatChieu', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ghe_SuatChieu
    (
        MaGhe VARCHAR(10) NOT NULL,
        MaSC INT NOT NULL,
        TrangThai INT NOT NULL DEFAULT 0,
        Version INT NOT NULL DEFAULT 1,

        CONSTRAINT PK_Ghe_SuatChieu
        PRIMARY KEY (MaGhe, MaSC),

        CONSTRAINT CK_TrangThai
        CHECK (TrangThai IN (0, 1, 2))
    );
END;
GO


-- ==========================================
-- 2. XOA STORED PROCEDURE CU NEU CO
-- ==========================================

IF OBJECT_ID('dbo.sp_GiuGhe_LacQuan', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GiuGhe_LacQuan;
GO

IF OBJECT_ID('dbo.sp_XacNhanThanhToan', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_XacNhanThanhToan;
GO


-- ==========================================
-- 3. STORED PROCEDURE GIU GHE
-- ==========================================

CREATE PROCEDURE dbo.sp_GiuGhe_LacQuan
    @MaGhe VARCHAR(10),
    @MaSC INT,
    @VersionCu INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SoDong INT;

    UPDATE dbo.Ghe_SuatChieu
    SET
        TrangThai = 1,
        Version = Version + 1
    WHERE
        MaGhe = @MaGhe
        AND MaSC = @MaSC
        AND TrangThai = 0
        AND Version = @VersionCu;

    SET @SoDong = @@ROWCOUNT;

    IF @SoDong = 0
    BEGIN
        SELECT N'THẤT BẠI: Ghế đã được đặt hoặc Version không hợp lệ.'
        AS ThongBao;
    END
    ELSE
    BEGIN
        SELECT N'THÀNH CÔNG: Giữ ghế thành công!'
        AS ThongBao;

        SELECT *
        FROM dbo.Ghe_SuatChieu
        WHERE MaGhe = @MaGhe
          AND MaSC = @MaSC;
    END
END;
GO


-- ==========================================
-- 4. STORED PROCEDURE XAC NHAN THANH TOAN
-- ==========================================

CREATE PROCEDURE dbo.sp_XacNhanThanhToan
    @MaGhe VARCHAR(10),
    @MaSC INT,
    @VersionCu INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SoDong INT;

    UPDATE dbo.Ghe_SuatChieu
    SET
        TrangThai = 2,
        Version = Version + 1
    WHERE
        MaGhe = @MaGhe
        AND MaSC = @MaSC
        AND TrangThai = 1
        AND Version = @VersionCu;

    SET @SoDong = @@ROWCOUNT;

    IF @SoDong = 0
    BEGIN
        SELECT N'THẤT BẠI: Ghế không còn hợp lệ.'
        AS ThongBao;
    END
    ELSE
    BEGIN
        SELECT N'THÀNH CÔNG: Thanh toán và xuất vé thành công!'
        AS ThongBao;

        SELECT *
        FROM dbo.Ghe_SuatChieu
        WHERE MaGhe = @MaGhe
          AND MaSC = @MaSC;
    END
END;
GO


-- ==========================================
-- 5. THEM DU LIEU MAU
-- ==========================================

-- Xoa du lieu mau cu de chay lai ket qua
DELETE FROM dbo.Ghe_SuatChieu
WHERE MaSC = 1
AND MaGhe IN ('H1', 'H2', 'H3');

INSERT INTO dbo.Ghe_SuatChieu
    (MaGhe, MaSC, TrangThai, Version)
VALUES
    ('H1', 1, 0, 1),
    ('H2', 1, 0, 1),
    ('H3', 1, 0, 1);
GO


-- ==========================================
-- 6. KHACH HANG A GIU GHE H1
-- ==========================================

EXEC dbo.sp_GiuGhe_LacQuan
    @MaGhe = 'H1',
    @MaSC = 1,
    @VersionCu = 1;
GO


-- ==========================================
-- 7. KHACH HANG B DAT LAI GHE H1
-- ==========================================

EXEC dbo.sp_GiuGhe_LacQuan
    @MaGhe = 'H1',
    @MaSC = 1,
    @VersionCu = 1;
GO


-- ==========================================
-- 8. KHACH HANG A XAC NHAN THANH TOAN
-- ==========================================

EXEC dbo.sp_XacNhanThanhToan
    @MaGhe = 'H1',
    @MaSC = 1,
    @VersionCu = 2;
GO


-- ==========================================
-- 9. KIEM TRA KET QUA CUOI CUNG
-- ==========================================

SELECT *
FROM dbo.Ghe_SuatChieu
ORDER BY MaSC, MaGhe;
GO


-- ==========================================
-- 1. TAO BANG NEU CHUA TON TAI
-- ==========================================

IF OBJECT_ID('dbo.Ghe_SuatChieu', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ghe_SuatChieu
    (
        MaGhe VARCHAR(10) NOT NULL,
        MaSC INT NOT NULL,
        TrangThai INT NOT NULL DEFAULT 0,
        Version INT NOT NULL DEFAULT 1,

        CONSTRAINT PK_Ghe_SuatChieu
        PRIMARY KEY (MaGhe, MaSC),

        CONSTRAINT CK_TrangThai
        CHECK (TrangThai IN (0, 1, 2))
    );
END;
GO

-- ==========================================
-- 2. TAO STORED PROCEDURE ROLLBACK
-- ==========================================

CREATE OR ALTER PROCEDURE dbo.sp_RollbackDatVe
    @MaGhe VARCHAR(10),
    @MaSC INT,
    @VersionCu INT,
    @ThanhToanThanhCong BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiem tra ghe dang duoc giu
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Ghe_SuatChieu
            WHERE MaGhe = @MaGhe
              AND MaSC = @MaSC
              AND TrangThai = 1
              AND Version = @VersionCu
        )
        BEGIN
            ROLLBACK TRANSACTION;

            SELECT N'THAT BAI: Ghe khong hop le hoac Version da thay doi.'
            AS ThongBao;

            RETURN;
        END;

        -- Truong hop thanh toan thanh cong
        IF @ThanhToanThanhCong = 1
        BEGIN
            UPDATE dbo.Ghe_SuatChieu
            SET TrangThai = 2,
                Version = Version + 1
            WHERE MaGhe = @MaGhe
              AND MaSC = @MaSC
              AND TrangThai = 1
              AND Version = @VersionCu;

            IF @@ROWCOUNT <> 1
                THROW 50001, N'Khong the xac nhan ban ghe.', 1;

            COMMIT TRANSACTION;

            SELECT N'THANH CONG: Thanh toan va ban ve thanh cong.'
            AS ThongBao;
        END
        ELSE
        BEGIN
            -- Thanh toan that bai: hoan tac giao dich
            ROLLBACK TRANSACTION;

            -- Tra ghe ve trang thai trong
            -- Su dung Version moi de tranh cap nhat sai du lieu
            UPDATE dbo.Ghe_SuatChieu
            SET TrangThai = 0,
                Version = Version + 1
            WHERE MaGhe = @MaGhe
              AND MaSC = @MaSC
              AND TrangThai = 1
              AND Version = @VersionCu;

            IF @@ROWCOUNT <> 1
            BEGIN
                SELECT N'THANH TOAN THAT BAI: Khong the tra ghe, vui long kiem tra lai.'
                AS ThongBao;
                RETURN;
            END;

            SELECT N'THANH TOAN THAT BAI: Da tra ghe ve trang thai trong.'
            AS ThongBao;
        END;

        -- Hien thi trang thai ghe
        SELECT MaGhe, MaSC, TrangThai, Version
        FROM dbo.Ghe_SuatChieu
        WHERE MaGhe = @MaGhe
          AND MaSC = @MaSC;

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SELECT ERROR_MESSAGE() AS Loi;

    END CATCH
END;
GO

-- ==========================================
-- 3. TAO DU LIEU MAU
-- ==========================================

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Ghe_SuatChieu
    WHERE MaGhe = 'R1' AND MaSC = 1
)
BEGIN
    INSERT INTO dbo.Ghe_SuatChieu
    (MaGhe, MaSC, TrangThai, Version)
    VALUES ('R1', 1, 1, 2);
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Ghe_SuatChieu
    WHERE MaGhe = 'R2' AND MaSC = 1
)
BEGIN
    INSERT INTO dbo.Ghe_SuatChieu
    (MaGhe, MaSC, TrangThai, Version)
    VALUES ('R2', 1, 1, 2);
END;
GO

-- ==========================================
-- 4. KIEM TRA THANH TOAN THAT BAI
-- ==========================================

EXEC dbo.sp_RollbackDatVe
    @MaGhe = 'R1',
    @MaSC = 1,
    @VersionCu = 2,
    @ThanhToanThanhCong = 0;
GO

-- ==========================================
-- 5. KIEM TRA THANH TOAN THANH CONG
-- ==========================================

EXEC dbo.sp_RollbackDatVe
    @MaGhe = 'R2',
    @MaSC = 1,
    @VersionCu = 2,
    @ThanhToanThanhCong = 1;
GO

-- ==========================================
-- 6. KIEM TRA KET QUA CUOI CUNG
-- ==========================================

SELECT *
FROM dbo.Ghe_SuatChieu
WHERE MaGhe IN ('R1', 'R2')
  AND MaSC = 1
ORDER BY MaGhe;
GO
