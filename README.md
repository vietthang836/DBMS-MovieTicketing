# DBMS-MovieTicketing
1. HOÀN THÀNH PROJECT CHARTER VÀ WBS
1.1. Project Charter (Tuyên ngôn dự án)
Tên dự án: Hệ thống quản lý đặt vé xem phim trực tuyến chống trùng chỗ (Trọng tâm: Xử lý truy cập đồng thời và Quản lý giao tác trong DBMS).
Lý do thực hiện (Business Case): Vào các dịp công chiếu bom tấn, lượng truy cập hệ thống đặt vé tăng đột biến. Nếu hệ quản trị CSDL chỉ sử dụng các lệnh SELECT/UPDATE cơ bản, hệ thống sẽ đối mặt với các xung đột dữ liệu nghiêm trọng: bán trùng 1 ghế cho nhiều người (Lost Update), lỗi thanh toán dẫn đến trạng thái ghế lấp lửng (Dirty Read), hoặc bế tắc (Deadlock). Dự án này được thực hiện để giải quyết triệt để bài toán cạnh tranh dữ liệu đó.
Mục tiêu dự án:
	• Thiết kế cơ sở dữ liệu tuân thủ nghiêm ngặt 4 thuộc tính ACID (Nguyên tử, Nhất quán, Cô lập, Bền vững).
	• Triển khai Khóa bi quan (Pessimistic Locking) và Khóa lạc quan (Optimistic Locking) thông qua trường Version để tối ưu tốc độ kiểm tra.
	• Giải quyết bài toán bế tắc (Deadlock) thông qua thuật toán ép buộc thứ tự khóa (Lock Ordering).
	• Ứng dụng Redis (thuật toán Redlock) để xử lý nghiệp vụ "giữ chỗ tạm thời 5 phút" trên RAM.
Phạm vi dự án (Scope):
	• Trong phạm vi: Thiết kế CSDL (Danh mục Phim, Phòng chiếu, Suất chiếu, Sơ đồ ghế, Giao dịch). Lập trình Stored Procedure quản lý Transaction. Xây dựng giao diện UI (C# .NET) để mô phỏng tương tác chọn vé.
	• Ngoài phạm vi: Không làm thanh toán thật (Momo/VNPay), Không làm AI gợi ý, Không làm Mobile App.
Các bên liên quan & Phân công cốt lõi:
	• Thành viên 1 (DB Designer): Phân tích thiết kế hệ thống, vẽ ERD, cấu trúc bảng CSDL.
	• Thành viên 2 (SQL Developer): Logic Stored Procedures, cấu hình Isolation Levels, Lock Hints, Rollback.
	• Thành viên 3 (UI/System Developer): Giao diện C#, cấu hình Redis Cache và Message Queue.
	• Thành viên 4 (QA/Technical Writer): Kịch bản stress test, lấy log chụp ảnh màn hình, tổng hợp báo cáo.
1.2. WBS (Work Breakdown Structure - Cấu trúc phân rã công việc)
1. Hạng mục 1: Khởi tạo và Phân tích Yêu cầu (Chương 1 & 2)
	1.1. Viết Tổng quan (Chương 1): Lý do, mục tiêu xử lý xung đột, phạm vi bài toán.
	1.2. Phân tích Nghiệp vụ (Chương 2): Vẽ Flowchart chu trình Chọn ghế -> Giữ chỗ (5 phút) -> Thanh toán.
	1.3. Phân tích Yêu cầu Kỹ thuật (Chương 2): Đặc tả tính ACID và lỗi Lost Update, Dirty Read, Deadlock.
2. Hạng mục 2: Thiết kế Cơ sở dữ liệu (Chương 3)
	2.1. Bảng Danh mục: NguoiDung, Phim, PhongChieu, SuatChieu.
	2.2. Bảng Cốt lõi: Ghe_SuatChieu bổ sung cột TrangThai (0: Trống, 1: Giữ, 2: Bán) và Version (Optimistic Locking).
	2.3. Bảng Giao dịch: GiaoDich_DatVe và ChiTietDatVe.
	2.4. Thiết kế ERD: Vẽ sơ đồ thực thể liên kết chuẩn 3NF.
3. Hạng mục 3: Lập trình CSDL & Xử lý Giao tác (Chương 4)
	3.1. Ràng buộc toàn vẹn: Trigger kiểm soát tổng số lượng ghế.
	3.2. Script Khóa Bi Quan: Stored Procedure dùng BEGIN TRAN và SELECT ... WITH (UPDLOCK).
	3.3. Script Khóa Lạc Quan: Lệnh UPDATE kiểm tra Version = Current_Version.
	3.4. Logic chống Bế tắc (Lock Ordering): Thuật toán sắp xếp ID ghế tăng dần trước khi khóa.
4. Hạng mục 4: Triển khai Hạ tầng Phân tải & Giao diện (Chương 4)
	4.1. Giao diện C# .NET: Code UI hiển thị lưới ghế. Nối API gọi Stored Procedure.
	4.2. Cấu hình Redis: Thuật toán Redlock quản lý "ghế đang giữ" trên RAM (TTL 300s).
	4.3. Message Queue: Cấu hình Kafka/RabbitMQ hứng giao dịch thanh toán.
5. Hạng mục 5: Kiểm thử, Đánh giá và Đóng gói (Chương 5)
	5.1. Stress Test: Mở 2 tab UI/Query, bấm mua cùng 1 ghế. Chụp log Success và log Deadlock/Wait.
	5.2. Đánh giá: Đánh đổi (Trade-off) giữa tốc độ và tính nhất quán (Eventual Consistency).
	5.3. Đóng gói: Hoàn thiện Word, Slide thuyết trình, Script .sql.
2. HOÀN THÀNH THIẾT LẬP MÔI TRƯỜNG THỰC THI TIỂU LUẬN
Đây là danh sách các công việc kỹ thuật nhóm cần thực hiện ngay trên máy tính để thiết lập môi trường:
2.1. Thiết lập Cơ sở dữ liệu (DBMS): Cài đặt Microsoft SQL Server Developer/Express Edition. Cài đặt và kết nối Azure Data Studio (hoặc SQL Server Management Studio) thông qua localhost (cổng 1433). Tạo Database trống tên RapPhim_DB.
2.2. Thiết lập Môi trường Phân tải & Cache: Cài đặt Redis (sử dụng Docker hoặc WSL nếu dùng Windows). Kiểm tra kết nối Redis qua Redis-CLI.
2.3. Thiết lập Môi trường Giao diện (UI): Cài đặt Visual Studio (hoặc VS Code). Khởi tạo Solution C# mới (.NET Windows Forms, WPF hoặc ASP.NET Core) để chuẩn bị code giao diện sơ đồ ghế.
2.4. Thiết lập Công cụ Làm việc nhóm: Tạo 1 Repository trên GitHub (ví dụ: DBMS-MovieTicketing) và mời 4 thành viên vào nhánh (branch). Khởi tạo 1 bảng Kanban trên Trello/Jira và nhập toàn bộ các mục trong WBS (Phần 1.2) lên Trello để giao việc (Assign) và theo dõi tiến độ (To Do -> Doing -> Done).
