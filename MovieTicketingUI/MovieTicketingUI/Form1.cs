using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace MovieTicketingUI
{
    public partial class Form1 : Form
    {
        private TicketService _service = new TicketService();
        private FlowLayoutPanel pnlSeats;
        private Label lblCartInfo;
        private Label lblTotalPrice;
        private Button btnCheckout;
        private Button btnRefresh;
        private ComboBox cboUser;
        private ComboBox cboLockMode;

        // Các nhãn hiển thị số lượng ghế thực tế theo từng trạng thái
        private Label lblCountFree;
        private Label lblCountHold;
        private Label lblCountSold;

        private List<SeatInfo> selectedSeats = new List<SeatInfo>();

        public Form1()
        {
            InitializeComponent();
            SetupFullUI();
            LoadSeatsFromDatabase();
        }

        private void Form1_Load(object sender, EventArgs e) { }
        private void flowLayoutPanel1_Paint(object sender, PaintEventArgs e) { }

        private void SetupFullUI()
        {
            this.Text = "Hệ Thống Đặt Vé Xem Phim Trực Tuyến - Chống Trùng Chỗ";
            this.Size = new Size(880, 530);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Controls.Clear();

            Label lblTitle = new Label()
            {
                Text = "MÀN HÌNH CHIẾU PHIM (AVATAR 3 - PHÒNG 01)",
                Font = new Font("Arial", 13, FontStyle.Bold),
                BackColor = Color.DarkSlateGray,
                ForeColor = Color.White,
                TextAlign = ContentAlignment.MiddleCenter,
                Location = new Point(40, 20),
                Size = new Size(430, 40)
            };
            this.Controls.Add(lblTitle);

            pnlSeats = new FlowLayoutPanel()
            {
                Location = new Point(40, 75),
                Size = new Size(430, 280),
                BorderStyle = BorderStyle.FixedSingle,
                FlowDirection = FlowDirection.LeftToRight,
                RightToLeft = RightToLeft.No
            };
            this.Controls.Add(pnlSeats);

            // Chú thích màu sắc & số lượng ghế thực tế
            lblCountFree = AddColorLegend(40, 368, Color.LightGreen, "Trống: 0");
            AddColorLegend(145, 368, Color.Gold, "Đang chọn");
            lblCountHold = AddColorLegend(255, 368, Color.Orange, "Đang giữ: 0");
            lblCountSold = AddColorLegend(375, 368, Color.Red, "Đã bán: 0");

            btnRefresh = new Button()
            {
                Text = "Tải lại trạng thái ghế từ SQL Server",
                Font = new Font("Arial", 9, FontStyle.Bold),
                Location = new Point(40, 410),
                Size = new Size(430, 40),
                Cursor = Cursors.Hand
            };
            btnRefresh.Click += (s, e) => LoadSeatsFromDatabase();
            this.Controls.Add(btnRefresh);

            GroupBox grpCart = new GroupBox()
            {
                Text = "GIỎ HÀNG && THANH TOÁN (SQL SERVER)",
                Font = new Font("Arial", 10, FontStyle.Bold),
                Location = new Point(500, 20),
                Size = new Size(330, 430)
            };
            this.Controls.Add(grpCart);

            // Chọn Khách hàng
            Label lblUser = new Label()
            {
                Text = "Tài khoản đặt vé:",
                Font = new Font("Arial", 9, FontStyle.Bold),
                Location = new Point(15, 30),
                Size = new Size(300, 20)
            };
            grpCart.Controls.Add(lblUser);

            cboUser = new ComboBox()
            {
                DropDownStyle = ComboBoxStyle.DropDownList,
                Font = new Font("Arial", 9, FontStyle.Regular),
                Location = new Point(15, 52),
                Size = new Size(300, 25)
            };
            cboUser.Items.Add("Khách Hàng A (MaND = 1)");
            cboUser.Items.Add("Khách Hàng B (MaND = 2)");
            cboUser.SelectedIndex = 0;
            grpCart.Controls.Add(cboUser);

            // Chọn Cơ chế khóa CSDL
            Label lblMode = new Label()
            {
                Text = "Cơ chế khóa CSDL (Concurrency):",
                Font = new Font("Arial", 9, FontStyle.Bold),
                Location = new Point(15, 88),
                Size = new Size(300, 20)
            };
            grpCart.Controls.Add(lblMode);

            cboLockMode = new ComboBox()
            {
                DropDownStyle = ComboBoxStyle.DropDownList,
                Font = new Font("Arial", 9, FontStyle.Regular),
                Location = new Point(15, 110),
                Size = new Size(300, 25)
            };
            cboLockMode.Items.Add("1. Khóa Bi Quan (UPDLOCK - Nhiều ghế)");
            cboLockMode.Items.Add("2. Khóa Lạc Quan (Version - 1 ghế)");
            cboLockMode.SelectedIndex = 0;
            grpCart.Controls.Add(cboLockMode);

            lblCartInfo = new Label()
            {
                Text = "Ghế đang chọn: Chưa chọn ghế nào",
                Font = new Font("Arial", 10, FontStyle.Regular),
                Location = new Point(15, 155),
                Size = new Size(300, 90)
            };
            grpCart.Controls.Add(lblCartInfo);

            lblTotalPrice = new Label()
            {
                Text = "Tổng tiền: 0 VNĐ",
                Font = new Font("Arial", 12, FontStyle.Bold),
                ForeColor = Color.DarkRed,
                Location = new Point(15, 260),
                Size = new Size(300, 30)
            };
            grpCart.Controls.Add(lblTotalPrice);

            btnCheckout = new Button()
            {
                Text = "GIỮ GHẾ && THANH TOÁN NGAY",
                Font = new Font("Arial", 10, FontStyle.Bold),
                BackColor = Color.DodgerBlue,
                ForeColor = Color.White,
                Location = new Point(15, 315),
                Size = new Size(300, 55),
                Cursor = Cursors.Hand
            };
            btnCheckout.Click += BtnCheckout_Click;
            grpCart.Controls.Add(btnCheckout);
        }

        private Label AddColorLegend(int x, int y, Color boxColor, string text)
        {
            Panel box = new Panel()
            {
                BackColor = boxColor,
                BorderStyle = BorderStyle.FixedSingle,
                Location = new Point(x, y),
                Size = new Size(16, 16)
            };
            Label lbl = new Label()
            {
                Text = text,
                Font = new Font("Arial", 8.5f, FontStyle.Regular),
                Location = new Point(x + 20, y),
                AutoSize = true
            };
            this.Controls.Add(box);
            this.Controls.Add(lbl);
            return lbl;
        }

        private void LoadSeatsFromDatabase()
        {
            try
            {
                selectedSeats.Clear();
                UpdateCartUI();
                pnlSeats.Controls.Clear();

                List<SeatInfo> seats = _service.GetSeatsFromDB(1);

                // Cập nhật số lượng ghế thực tế theo từng trạng thái từ SQL Server
                lblCountFree.Text = $"Trống: {seats.Count(s => s.TrangThai == 0)}";
                lblCountHold.Text = $"Đang giữ: {seats.Count(s => s.TrangThai == 1)}";
                lblCountSold.Text = $"Đã bán: {seats.Count(s => s.TrangThai == 2)}";

                foreach (var seat in seats)
                {
                    Button btnSeat = new Button()
                    {
                        Text = $"{seat.TenGhe}\n(v{seat.Version})",
                        Name = "btnSeat_" + seat.MaGhe,
                        Tag = seat,
                        Width = 85,
                        Height = 75,
                        Margin = new Padding(10),
                        Font = new Font("Arial", 9.5f, FontStyle.Bold),
                        Cursor = Cursors.Hand
                    };

                    if (seat.TrangThai == 0)
                    {
                        btnSeat.BackColor = Color.LightGreen;
                    }
                    else if (seat.TrangThai == 1)
                    {
                        btnSeat.BackColor = Color.Orange;
                        btnSeat.Enabled = false;
                    }
                    else
                    {
                        btnSeat.BackColor = Color.Red;
                        btnSeat.ForeColor = Color.White;
                        btnSeat.Enabled = false;
                    }

                    btnSeat.Click += Seat_Click;
                    pnlSeats.Controls.Add(btnSeat);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải dữ liệu từ SQL Server:\n" + ex.Message, "Lỗi Kết Nối", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void Seat_Click(object sender, EventArgs e)
        {
            Button btn = sender as Button;
            SeatInfo seat = btn?.Tag as SeatInfo;
            if (seat == null) return;

            if (btn.BackColor == Color.LightGreen)
            {
                btn.BackColor = Color.Gold;
                selectedSeats.Add(seat);
            }
            else if (btn.BackColor == Color.Gold)
            {
                btn.BackColor = Color.LightGreen;
                selectedSeats.Remove(seat);
            }

            UpdateCartUI();
        }

        private void UpdateCartUI()
        {
            if (selectedSeats.Count == 0)
            {
                lblCartInfo.Text = "Ghế đang chọn: Chưa chọn ghế nào";
                lblTotalPrice.Text = "Tổng tiền: 0 VNĐ";
            }
            else
            {
                string names = string.Join(", ", selectedSeats.Select(s => $"{s.TenGhe} (v{s.Version})"));
                decimal total = selectedSeats.Sum(s => s.GiaVe);
                lblCartInfo.Text = $"Ghế đang chọn ({selectedSeats.Count} ghế):\n{names}";
                lblTotalPrice.Text = $"Tổng tiền: {total:N0} VNĐ";
            }
        }

        private void BtnCheckout_Click(object sender, EventArgs e)
        {
            if (selectedSeats.Count == 0)
            {
                MessageBox.Show("Vui lòng chọn ít nhất 1 ghế trống!", "Nhắc nhở", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            int maND = cboUser.SelectedIndex + 1;
            bool isOptimistic = (cboLockMode.SelectedIndex == 1);

            if (isOptimistic && selectedSeats.Count > 1)
            {
                MessageBox.Show("Chế độ Khóa Lạc Quan (sp_GiuGhe_LacQuan) chỉ hỗ trợ giữ từng ghế một. Vui lòng bỏ chọn bớt chỉ giữ lại 1 ghế!", "Lưu ý", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            try
            {
                btnCheckout.Enabled = false;
                btnCheckout.Text = "ĐANG XỬ LÝ KHÓA TRÊN SQL...";
                Application.DoEvents();

                (bool Success, string Message, long MaGD) holdResult;

                if (isOptimistic)
                {
                    SeatInfo seat = selectedSeats[0];
                    holdResult = _service.HoldSeatOptimistic(seat.MaGhe, seat.Version, maSC: 1, maND: maND);
                }
                else
                {
                    string danhSachMaGhe = string.Join(",", selectedSeats.Select(s => s.MaGhe));
                    holdResult = _service.HoldSeatsPessimistic(danhSachMaGhe, maSC: 1, maND: maND);
                }

                if (!holdResult.Success)
                {
                    MessageBox.Show(holdResult.Message, "CẢNH BÁO XUNG ĐỘT GHẾ (SQL SERVER)", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    LoadSeatsFromDatabase();
                    return;
                }

                DialogResult payConfirm = MessageBox.Show(
                    $"{holdResult.Message}\nKhách hàng: {cboUser.Text}\nMã Giao Dịch: {holdResult.MaGD}\n\nBạn có muốn hoàn tất thanh toán ngay không?\n(Yes = Thanh toán thành công | No = Giả lập lỗi để Rollback trả ghế)",
                    "Xác Nhận Thanh Toán",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question);

                bool isPaySuccess = (payConfirm == DialogResult.Yes);
                var payResult = _service.ProcessPayment(holdResult.MaGD, "Chuyển khoản QR", isPaySuccess);

                MessageBox.Show(payResult.Message, isPaySuccess ? "Xuất Vé Thành Công" : "Đã Hoàn Tác (Rollback)", MessageBoxButtons.OK, MessageBoxIcon.Information);

                LoadSeatsFromDatabase();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi hệ thống: " + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCheckout.Enabled = true;
                btnCheckout.Text = "GIỮ GHẾ && THANH TOÁN NGAY";
            }
        }
    }
}