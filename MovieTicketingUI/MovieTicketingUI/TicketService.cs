using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace MovieTicketingUI
{
    public class SeatInfo
    {
        public int MaGhe { get; set; }
        public string TenGhe { get; set; }
        public int TrangThai { get; set; } // 0: Trống, 1: Giữ, 2: Bán
        public int Version { get; set; }
        public decimal GiaVe { get; set; }
    }

    public class TicketService
    {
        // ĐỔI MẬT KHẨU SA CỦA BẠN VÀO CHỖ NÀY:
        private string connString = @"Server=localhost;Database=CinemaBooking;User Id=sa;Password=Sql@2026Password!;Encrypt=False;TrustServerCertificate=True;";

        public List<SeatInfo> GetSeatsFromDB(int maSC = 1)
        {
            List<SeatInfo> list = new List<SeatInfo>();
            string query = @"
                SELECT g.MaGhe, g.TenGhe, gs.TrangThai, gs.Version, sc.GiaVe
                FROM dbo.Ghe_SuatChieu gs
                JOIN dbo.Ghe g ON gs.MaGhe = g.MaGhe
                JOIN dbo.SuatChieu sc ON gs.MaSC = sc.MaSC
                WHERE gs.MaSC = @MaSC
                ORDER BY g.MaGhe ASC";

            using (SqlConnection conn = new SqlConnection(connString))
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@MaSC", maSC);
                conn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new SeatInfo
                        {
                            MaGhe = Convert.ToInt32(reader["MaGhe"]),
                            TenGhe = reader["TenGhe"].ToString(),
                            TrangThai = Convert.ToInt32(reader["TrangThai"]),
                            Version = Convert.ToInt32(reader["Version"]),
                            GiaVe = Convert.ToDecimal(reader["GiaVe"])
                        });
                    }
                }
            }
            return list;
        }

        // Cơ chế 1: Khóa Lạc Quan (Optimistic Locking) kiểm tra Version
        public (bool Success, string Message, long MaGD) HoldSeatOptimistic(int maGhe, int versionCu, int maSC = 1, int maND = 1)
        {
            using (SqlConnection conn = new SqlConnection(connString))
            using (SqlCommand cmd = new SqlCommand("dbo.sp_GiuGhe_LacQuan", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@MaGhe", maGhe);
                cmd.Parameters.AddWithValue("@MaSC", maSC);
                cmd.Parameters.AddWithValue("@MaND", maND);
                cmd.Parameters.AddWithValue("@VersionCu", versionCu);

                conn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        if (reader.GetName(0) == "ThongBao")
                        {
                            string msg = reader["ThongBao"].ToString();
                            bool isOk = msg.StartsWith("THÀNH CÔNG");
                            long maGD = isOk ? Convert.ToInt64(reader["MaGiaoDich"]) : 0;
                            return (isOk, msg, maGD);
                        }
                        return (false, "Lỗi SQL: " + reader[0], 0);
                    }
                }
            }
            return (false, "Không nhận được phản hồi từ SQL Server.", 0);
        }

        // Cơ chế 2: Khóa Bi Quan (Pessimistic Locking - UPDLOCK + Lock Ordering)
        public (bool Success, string Message, long MaGD) HoldSeatsPessimistic(string danhSachMaGhe, int maSC = 1, int maND = 1)
        {
            using (SqlConnection conn = new SqlConnection(connString))
            using (SqlCommand cmd = new SqlCommand("dbo.sp_GiuNhieuGhe_BiQuan_ChongDeadlock", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@DanhSachMaGhe", danhSachMaGhe);
                cmd.Parameters.AddWithValue("@MaSC", maSC);
                cmd.Parameters.AddWithValue("@MaND", maND);

                conn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        if (reader.GetName(0) == "ThongBao")
                        {
                            string msg = reader["ThongBao"].ToString();
                            bool isOk = msg.StartsWith("THÀNH CÔNG");
                            long maGD = isOk ? Convert.ToInt64(reader["MaGiaoDich"]) : 0;
                            return (isOk, msg, maGD);
                        }
                        else if (reader.GetName(0) == "MaLoi")
                        {
                            return (false, "Lỗi SQL (" + reader["MaLoi"] + "): " + reader["ChiTietLoi"], 0);
                        }
                    }
                }
            }
            return (false, "Không nhận được phản hồi từ SQL Server.", 0);
        }

        // Xử lý Thanh toán hoặc Rollback
        public (bool Success, string Message) ProcessPayment(long maGD, string phuongThuc, bool isSuccess)
        {
            using (SqlConnection conn = new SqlConnection(connString))
            using (SqlCommand cmd = new SqlCommand("dbo.sp_XuLyThanhToan", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@MaGD", maGD);
                cmd.Parameters.AddWithValue("@PhuongThuc", phuongThuc);
                cmd.Parameters.AddWithValue("@ThanhToanThanhCong", isSuccess ? 1 : 0);

                conn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        string msg = reader[0].ToString();
                        return (msg.StartsWith("THÀNH CÔNG"), msg);
                    }
                }
            }
            return (false, "Lỗi xử lý thanh toán.");
        }
    }
}