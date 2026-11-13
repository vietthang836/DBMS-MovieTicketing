USE CinemaBooking;
EXEC dbo.sp_XuLyThanhToan @MaGD = 1, @PhuongThuc = N'MoMo', @ThanhToanThanhCong = 0;
SELECT * FROM dbo.Ghe_SuatChieu;