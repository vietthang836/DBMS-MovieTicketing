-- ============================================================
-- CHƯƠNG 3: THIẾT KẾ VÀ KHỞI TẠO CƠ SỞ DỮ LIỆU DỰ ÁN
-- Đề tài: Hệ thống quản lý đặt vé xem phim trực tuyến (TV1)
-- ============================================================

-- 1. Tạo Cơ sở dữ liệu
CREATE DATABASE MovieTicketingDB;
GO

USE MovieTicketingDB;
GO

-- 2. Bảng Rạp chiếu phim (Cinema)
CREATE TABLE Cinema (
    CinemaID INT IDENTITY(1,1) PRIMARY KEY,
    CinemaName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255) NOT NULL
);

-- 3. Bảng Phòng chiếu (ScreenRoom)
CREATE TABLE ScreenRoom (
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomName NVARCHAR(50) NOT NULL,
    CinemaID INT NOT NULL,
    FOREIGN KEY (CinemaID) REFERENCES Cinema(CinemaID)
);

-- 4. Bảng Phim (Movie)
CREATE TABLE Movie (
    MovieID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(150) NOT NULL,
    Duration INT NOT NULL, -- Thời lượng (phút)
    ReleaseDate DATE
);

-- 5. Bảng Suất chiếu (Showtime)
CREATE TABLE Showtime (
    ShowtimeID INT IDENTITY(1,1) PRIMARY KEY,
    MovieID INT NOT NULL,
    RoomID INT NOT NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (MovieID) REFERENCES Movie(MovieID),
    FOREIGN KEY (RoomID) REFERENCES ScreenRoom(RoomID)
);

-- 6. Bảng Ghế (Seat)
CREATE TABLE Seat (
    SeatID INT IDENTITY(1,1) PRIMARY KEY,
    RoomID INT NOT NULL,
    SeatNumber VARCHAR(10) NOT NULL, -- Ví dụ: A1, A2, B5
    SeatType NVARCHAR(20) DEFAULT N'Standard', -- Standard, VIP, Couple
    FOREIGN KEY (RoomID) REFERENCES ScreenRoom(RoomID)
);

-- 7. Bảng Người dùng (Users)
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15)
);

-- 8. Bảng Đặt vé / Trạng thái giữ ghế (TicketBooking) - CỐT LÕI CHỐNG TRÙNG GHẾ
CREATE TABLE TicketBooking (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    ShowtimeID INT NOT NULL,
    SeatID INT NOT NULL,
    UserID INT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT N'AVAILABLE', -- AVAILABLE, HOLDING, BOOKED
    HoldTime DATETIME NULL, -- Thời gian bắt đầu giữ ghế
    Version ROWVERSION NOT NULL, -- Cột Timestamp/Version phục vụ Khóa lạc quan (Optimistic Concurrency)
    FOREIGN KEY (ShowtimeID) REFERENCES Showtime(ShowtimeID),
    FOREIGN KEY (SeatID) REFERENCES Seat(SeatID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT UQ_Showtime_Seat UNIQUE (ShowtimeID, SeatID) -- Đảm bảo 1 ghế trong 1 suất chiếu chỉ có 1 dòng dữ liệu
);
GO

-- ============================================================
-- DỮ LIỆU MẪU BAN ĐẦU (SEED DATA TEST SYSTEM)
-- ============================================================

INSERT INTO Cinema (CinemaName, Address) VALUES (N'CGV Vincom', N'Q1, TP.HCM');
INSERT INTO ScreenRoom (RoomName, CinemaID) VALUES (N'Phòng 01', 1);
INSERT INTO Movie (Title, Duration, ReleaseDate) VALUES (N'Avatar 3', 180, '2026-12-01');

INSERT INTO Showtime (MovieID, RoomID, StartTime, EndTime, Price) 
VALUES (1, 1, '2026-11-10 19:00:00', '2026-11-10 22:00:00', 100000);

-- Tạo 5 ghế mẫu
INSERT INTO Seat (RoomID, SeatNumber) VALUES (1, 'A1'), (1, 'A2'), (1, 'A3'), (1, 'A4'), (1, 'A5');

-- Khởi tạo trạng thái ghế trống cho Suất chiếu #1
INSERT INTO TicketBooking (ShowtimeID, SeatID, Status) VALUES 
(1, 1, N'AVAILABLE'),
(1, 2, N'AVAILABLE'),
(1, 3, N'AVAILABLE'),
(1, 4, N'AVAILABLE'),
(1, 5, N'AVAILABLE');
GO