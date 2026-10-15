# 🚀 Siêu Máy Chủ Docker (Cấu Trúc Phân Tách Chuyên Nghiệp)

Môi trường phát triển Web PHP chuyên nghiệp dựa trên **Docker**, thay thế hoàn toàn XAMPP. Hệ thống được tối ưu hóa để tách biệt cấu hình hệ thống và mã nguồn dự án, giúp quản lý linh hoạt và bảo mật hơn.

## 🛠 Cấu trúc thư mục

Hệ thống được tổ chức để giữ cho thư mục gốc sạch sẽ, toàn bộ code dự án nằm trong thư mục `www`, toàn bộ dữ liệu CSDL được cô lập an toàn tại máy thật trong thư mục `data`:

```text
~/Projects/
├── data/                   # <-- THƯ MỤC CHỨA DỮ LIỆU CSDL (Tự động sinh ra)
│   ├── mysql/              # Dữ liệu MySQL
│   ├── sqlserver/          # Dữ liệu SQL Server
│   ├── postgres/           # Dữ liệu PostgreSQL
│   └── mongo/              # Dữ liệu MongoDB
├── www/                    # <-- THƯ MỤC CHỨA CODE DỰ ÁN
│   ├── info.php            # File kiểm tra cấu hình PHP
│   └── test_db.php         # File kiểm tra kết nối Database
├── .env                    # Lưu trữ các biến mật khẩu (Tự động sinh ra khi chạy script)
├── Dockerfile              # Cấu hình Build PHP 8.2 & Driver CSDL
├── docker-compose.yml      # Điều phối toàn bộ hệ thống Container
├── setup-for-linux.sh      # Script cài đặt & quản trị cho Linux / macOS
├── setup-for-window.bat    # Script cài đặt & quản trị cho Windows
└── README.md               # Tài liệu hướng dẫn này
```

---

## ⚙️ Hướng dẫn sử dụng Script Quản Trị

Cả 2 file script `setup-for-linux.sh` (Linux/macOS) và `setup-for-window.bat` (Windows) đều được tích hợp **Menu điều khiển 3 tùy chọn**:

```text
1. Cài mới (Dọn dẹp toàn bộ dữ liệu & cài đặt lại từ đầu)
2. Cài thêm / Cài lại dịch vụ
3. Đổi mật khẩu dịch vụ
```

### A. Trên Linux / macOS

1. **Yêu cầu:** Máy tính đã cài đặt **Docker** và **Docker Compose**.
2. **Triển khai:**
   * Mở Terminal tại thư mục dự án.
   * Cấp quyền thực thi và chạy script:
   ```bash
   chmod +x setup-for-linux.sh
   ./setup-for-linux.sh
   ```

### B. Trên Windows

1. **Yêu cầu:** Đã cài đặt **Docker Desktop** (khuyên dùng WSL 2 backend) và đang bật.
2. **Triển khai:**
   * Nhấp đúp chuột (Double-click) vào file `setup-for-window.bat` để chạy trực tiếp.
   * Hoặc mở **CMD / PowerShell** tại thư mục dự án và gõ:
   ```cmd
   setup-for-window.bat
   ```

---

## 🧭 Chi tiết các chế độ hoạt động

### 1️⃣ Tùy chọn 1: Cài mới
* **Người mới cài lần đầu:** Hệ thống tự động nhận diện chưa có dữ liệu cũ và tiến hành cài đặt ngay, không hiển thị cảnh báo xóa.
* **Người đã có dữ liệu muốn cài lại:** Hệ thống hiển thị cảnh báo xác nhận `(y/N)`. Khi đồng ý, toàn bộ containers cũ và thư mục `./data` sẽ được dọn dẹp sạch sẽ để dựng lại từ đầu.
* Cho phép chọn các CSDL muốn cài đặt (MySQL, SQL Server, PostgreSQL, MongoDB, Redis).
* Yêu cầu nhập mật khẩu admin ban đầu và tự động lưu vào file `.env`.

### 2️⃣ Tùy chọn 2: Cài thêm / Cài lại dịch vụ
* **Tận dụng dữ liệu hiện có:** Tự động đọc mật khẩu từ file `.env`, không bắt nhập lại nếu đã có.
* **Không làm mất dữ liệu các dịch vụ khác:**
  * Dịch vụ chưa cài: Cho phép chọn để cài thêm mới.
  * Dịch vụ đã tồn tại: Hệ thống thông báo đã tồn tại và hỏi bạn có muốn cài lại không. Nếu chọn cài lại, script sẽ hỏi xác nhận có muốn xóa dữ liệu của riêng dịch vụ đó không rồi mới cài lại.

### 3️⃣ Tùy chọn 3: Đổi mật khẩu
* Cho phép đổi mật khẩu độc lập cho từng CSDL:
  1. **MySQL** (`root`)
  2. **SQL Server** (`sa`)
  3. **PostgreSQL** (`postgres`)
  4. **MongoDB** (`root`)
  5. Cập nhật biến mật khẩu bất kỳ trong file `.env`
* Script tự chạy lệnh trực tiếp vào trong container để đổi mật khẩu và đồng bộ ngay vào biến tương ứng trong `.env` mà không làm ảnh hưởng các CSDL khác.

---

## 💻 Cách làm việc hàng ngày (Tiết kiệm RAM)

Hệ thống được cấu hình ở chế độ **Thủ công (Manual)**. Bạn chỉ bật những gì thực sự cần dùng để máy tính luôn chạy mượt mà và giải phóng RAM tối đa.

### Bước 1: Khởi động Web Server (Apache & PHP)
```bash
docker compose up -d web-app
```
*(Chỉ bật Apache và PHP, hoàn toàn độc lập và không tự động kéo theo bất kỳ CSDL nào).*

### Bước 2: Bật Database khi cần sử dụng
Mở Terminal / PowerShell và bật container tương ứng:
```bash
docker start mysql_db
# Hoặc các database khác:
# docker start sqlserver_db
# docker start postgres_db
# docker start mongo_db
# docker start redis_cache
```

### Bước 3: Tắt toàn bộ khi xong việc
Khi kết thúc ngày làm việc, tắt mọi dịch vụ đang chạy ngầm để giải phóng RAM:
```bash
docker compose stop
```

---

## 📊 Thông số kết nối Cơ sở dữ liệu

Từng CSDL sử dụng biến mật khẩu độc lập trong file `.env` (mặc định ban đầu sẽ lấy theo mật khẩu bạn nhập lúc setup):

| Dịch vụ | Hostname (Nội bộ Docker) | Hostname (Máy thật) | Port | Tài khoản (Username) | Biến mật khẩu trong `.env` |
| --- | --- | --- | --- | --- | --- |
| **MySQL** | `mysql` | `localhost` | 3306 | `root` | `MYSQL_ROOT_PASSWORD` |
| **PostgreSQL** | `postgres` | `localhost` | 5432 | `postgres` | `POSTGRES_PASSWORD` |
| **SQL Server** | `sqlserver_db` | `localhost` | 1433 | `sa` | `MSSQL_SA_PASSWORD` |
| **MongoDB** | `mongodb` | `localhost` | 27017 | `root` | `MONGO_INITDB_ROOT_PASSWORD` |
| **Redis** | `redis` | `localhost` | 6379 | *(Không yêu cầu)* | *(Không mật khẩu)* |

### Quản trị Database trực tiếp trên Web bằng Adminer
* **Truy cập:** `http://localhost:8080`
* **System:** Chọn loại DB tương ứng (MySQL, PostgreSQL, MS SQL).
* **Server:** Nhập tên service trong Docker (VD: `mysql`, `postgres`, `sqlserver_db`). **Không dùng `localhost`**.
* **Username & Password:** Nhập tài khoản và mật khẩu tương ứng của CSDL đó.

### Quản lý bằng phần mềm trên máy thật (DBeaver / Compass)
* **DBeaver (MySQL, Postgres, SQL Server):** Host là `localhost`, port và tài khoản theo bảng trên.
  *(Với SQL Server: Vào thẻ `Driver Properties` đặt `TrustServerCertificate = true`).*
* **MongoDB Compass:**
  ```text
  mongodb://root:<MậtKhẩuMongo>@localhost:27017/
  ```

---

## 🌐 Đường dẫn truy cập nhanh

* **Trình quản lý tệp dự án:** `http://localhost/` (Xem danh sách mã nguồn trong thư mục `www`).
* **Kiểm tra thông tin PHP:** `http://localhost/info.php`.
* **Kiểm tra kết nối DB:** `http://localhost/test_db.php`.
* **Quản trị Database trực quan (Adminer):** `http://localhost:8080`.
