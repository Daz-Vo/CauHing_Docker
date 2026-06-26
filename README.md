
---

# 🚀 Siêu Máy Chủ Docker (Cấu Trúc Phân Tách Chuyên Nghiệp)

Môi trường phát triển Web PHP chuyên nghiệp dựa trên **Docker**, thay thế hoàn toàn XAMPP. Hệ thống được tối ưu hóa để tách biệt cấu hình hệ thống và mã nguồn dự án, giúp quản lý linh hoạt và bảo mật hơn.

## 🛠 Cấu trúc thư mục

Hệ thống được tổ chức để giữ cho thư mục gốc sạch sẽ, toàn bộ code dự án nằm trong thư mục `www`, toàn bộ dữ liệu CSDL được cô lập an toàn tại máy thật trong thư mục `data`:

```text
~/Projects/
├── data/               # <-- THƯ MỤC CHỨA DỮ LIỆU CSDL (Tự động sinh ra)
│   ├── mysql/          # Dữ liệu MySQL
│   ├── sqlserver/      # Dữ liệu SQL Server
│   ├── postgres/       # Dữ liệu PostgreSQL
│   └── mongo/          # Dữ liệu MongoDB
├── www/                # <-- THƯ MỤC CHỨA CODE DỰ ÁN
│   ├── Web/            # Dự án Web
│   ├── Game/           # Dự án Game
│   ├── info.php        # File kiểm tra cấu hình PHP
│   └── test_db.php     # File kiểm tra kết nối Database
├── .env                # Lưu trữ mật khẩu chung (Tự động sinh ra khi chạy script)
├── Dockerfile          # Cấu hình Build PHP 8.2 & Driver CSDL
├── docker-compose.yml  # Điều phối toàn bộ hệ thống Container
└── README.md           # Tài liệu hướng dẫn này (File này)

```

---

## ⚙️ Hướng dẫn cài đặt lần đầu

Dự án này bắt buộc người dùng phải **tự thiết lập mật khẩu Admin** khi cài đặt nhằm tăng tính bảo mật cho môi trường dev.

### A. Trên Linux / macOS

1. **Yêu cầu:** Máy tính đã cài đặt **Docker** và **Docker Compose**.
2. **Triển khai:**
* Mở Terminal tại thư mục dự án.
* Cấp quyền thực thi và chạy script:
```bash
chmod +x setup-project.sh
./setup-project.sh

```


* **Lưu ý:** Script sẽ yêu cầu bạn chọn CSDL muốn bật, sau đó **bắt buộc bạn phải gõ nhập mật khẩu Admin dùng chung** (không được để trống) để khởi chạy hệ thống.



### B. Trên Windows

1. **Yêu cầu:** Đã cài đặt **Docker Desktop** (khuyên dùng WSL 2 backend) và đang khởi chạy.
2. **Triển khai:**
* Nhấp đúp chuột (Double-click) vào file `setup-project.bat` để chạy trực tiếp.
* Hoặc mở **CMD / PowerShell** tại thư mục dự án và chạy:
```cmd
setup-project.bat

```


* **Lưu ý:** Tương tự như bản Linux, hệ thống sẽ kiểm tra và yêu cầu bạn **bắt buộc gõ nhập mật khẩu Admin dùng chung**, nếu để trống script sẽ cảnh báo lỗi và không cho phép đi tiếp.



---

## 💻 Cách làm việc hàng ngày (Tiết kiệm RAM)

Hệ thống được cấu hình ở chế độ **Thủ công (Manual)**. Bạn chỉ bật những gì thực sự cần dùng để máy tính luôn chạy mượt mà và giải phóng RAM tối đa.

### Bước 1: Khởi động Web Server (Apache & PHP)

Dù trên Windows hay Linux, hãy mở dòng lệnh tại thư mục dự án và chạy:

```bash
docker compose up -d web-app

```

*(Lệnh này chỉ bật Apache và PHP, hoàn toàn độc lập và không tự động kéo theo bất kỳ CSDL nào).*

### Bước 2: Bật Database khi cần sử dụng

Khi dự án của bạn cần kết nối Cơ sở dữ liệu, hãy mở Terminal/CMD/PowerShell và bật thủ công container tương ứng:

```bash
docker start mysql_db
# Hoặc các database khác:
# docker start sqlserver_db
# docker start postgres_db
# docker start mongo_db

```

### Bước 3: Tắt toàn bộ khi xong việc

Khi kết thúc ngày làm việc, hãy tắt mọi dịch vụ đang chạy ngầm để giải phóng RAM cho máy tính bằng lệnh:

```bash
docker compose stop

```

---

## 📊 Thông số kết nối Cơ sở dữ liệu

Toàn bộ hệ thống đã được cấu hình đồng bộ hóa để chạy bằng **Tài khoản gốc tối cao (Superuser/Admin)** của từng hãng với **Mật khẩu dùng chung** mà bạn đã nhập khi cài đặt.

### A. Kết nối từ Code PHP (Bên trong mạng nội bộ Docker)

Sử dụng **Hostname** là tên của Service được định nghĩa trong file compose.

| Dịch vụ | Hostname | Cổng (Port) | Tài khoản (Username) | Mật khẩu (Password) |
| --- | --- | --- | --- | --- |
| **MySQL** | `mysql` | 3306 | `root` | *Mật khẩu bạn đã nhập* |
| **PostgreSQL** | `postgres` | 5432 | `postgres` | *Mật khẩu bạn đã nhập* |
| **SQL Server** | `sqlserver_db` | 1433 | `sa` | *Mật khẩu bạn đã nhập* |
| **MongoDB** | `mongodb` | 27017 | `root` | *Mật khẩu bạn đã nhập* |

### B. Quản trị Database trực tiếp trên Web bằng Adminer (Khuyên dùng)

Công cụ Adminer siêu nhẹ đã được tích hợp sẵn giúp bạn quản lý các SQL Database (MySQL, PostgreSQL, MS SQL) mà không cần cài phần mềm thứ 3.
* **Truy cập:** Mở trình duyệt và vào `http://localhost:8080`.
* **Cách đăng nhập:**
  * **System (Hệ quản trị):** Chọn loại DB bạn muốn (ví dụ: MySQL).
  * **Server (Máy chủ):** Gõ tên service tương ứng trong Docker (VD: `mysql`, `postgres`, hoặc `sqlserver_db`). **TUYỆT ĐỐI KHÔNG dùng `localhost`**.
  * **Username & Password:** Nhập tài khoản và mật khẩu như bảng ở mục A (Mật khẩu chính là mật khẩu dùng chung bạn đã tạo lúc Setup).

### C. Quản lý bằng phần mềm trên máy thật (DBeaver & MongoDB Compass)

Để quản trị cơ sở dữ liệu trực quan từ môi trường máy thật bằng phần mềm cài đặt ngoài:

**1. Quản lý SQL (MySQL, PostgreSQL, SQL Server) bằng DBeaver CE:**

* **Cách kết nối:** Sử dụng Hostname là **`localhost`** thay vì tên service nội bộ.
* **MySQL:** `localhost:3306`
* **PostgreSQL:** `localhost:5432`
* **SQL Server:** `localhost:1433` *(Mẹo: Vào thẻ `Driver Properties` chuyển thuộc tính `TrustServerCertificate` thành `true` để bỏ qua lỗi chứng chỉ SSL).*


* Tài khoản và mật khẩu nhập chính xác theo bảng ở mục A.

**2. Quản lý NoSQL bằng MongoDB Compass:**

* **Chuỗi kết nối (URI) trọn gói:** *(Thay thế `MatKhauCuaBan` bằng mật khẩu bạn đã cài)*
```text
mongodb://root:MatKhauCuaBan@localhost:27017/

```

**3. Quản lý Cache bằng RedisInsight:**

* **Phần mềm khuyên dùng:** "RedisInsight" hoặc Another Redis Desktop Manager.
* **Cách kết nối:**
  * **Host:** `localhost` hoặc `127.0.0.1`
  * **Port:** `6379`
  * **Mật khẩu:** Bỏ trống (Mặc định không yêu cầu).

---

## 🌐 Đường dẫn truy cập nhanh

* **Trình quản lý tệp dự án:** `http://localhost/` (Liệt kê tất cả thư mục/mã nguồn nằm trong folder `www`).
* **Kiểm tra thông tin PHP:** `http://localhost/info.php`.
* **Kiểm tra kết nối DB:** `http://localhost/test_db.php`.
* **Quản trị Database trực quan (Adminer):** `http://localhost:8080` (Hỗ trợ MySQL, PostgreSQL, SQL Server).

---
