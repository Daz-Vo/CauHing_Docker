@echo off
chcp 65001 > nul
echo ==============================================
echo    HỆ THỐNG TỰ ĐỘNG TRIỂN KHAI DOCKER DEV
echo ==============================================

rem 1. Kiểm tra Docker
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [LỖI] Docker chưa được cài đặt. Vui lòng cài Docker/Docker Desktop trước!
    pause
    exit /b 1
)

rem 2. Hỏi người dùng chọn CSDL
echo Chọn các cơ sở dữ liệu bạn muốn cài đặt/kích hoạt:
set /p install_mysql="1. Cài đặt MySQL? (Y/N, mặc định Y): "
set /p install_mssql="2. Cài đặt SQL Server (MSSQL)? (Y/N, mặc định Y): "
set /p install_postgres="3. Cài đặt PostgreSQL? (Y/N, mặc định Y): "
set /p install_mongo="4. Cài đặt MongoDB? (Y/N, mặc định Y): "
set /p install_redis="5. Cài đặt Redis? (Y/N, mặc định Y): "

rem Thiết lập giá trị mặc định nếu nhấn Enter (Không nhập gì)
if "%install_mysql%"=="" set install_mysql=Y
if "%install_mssql%"=="" set install_mssql=Y
if "%install_postgres%"=="" set install_postgres=Y
if "%install_mongo%"=="" set install_mongo=Y
if "%install_redis%"=="" set install_redis=Y

rem 2.5 Hỏi mật khẩu dùng chung cho Admin tối cao (Bắt buộc nhập)
echo.
echo ==============================================
echo    THIẾT LẬP MẬT KHẨU DÙNG CHUNG CHO ADMIN
echo ==============================================

:ASK_PASSWORD
set "DEV_PASSWORD="
set /p DEV_PASSWORD="Nhập mật khẩu chung (Bắt buộc): "

rem Kiểm tra xem biến có bị rỗng hay không
if "%DEV_PASSWORD%"=="" (
    echo [LỖI] Mật khẩu không được để trống! Vui lòng nhập lại.
    echo.
    goto ASK_PASSWORD
)

rem Tự động ghi biến mật khẩu ra file .env để Docker Compose đọc
echo DEV_PASSWORD=%DEV_PASSWORD% > .env

rem 3. Dọn dẹp container cũ
echo [1/4] Đang dọn dẹp các container cũ...
docker compose down --remove-orphans >nul 2>nul

rem 4. Build image PHP
echo [2/4] Đang build Image PHP tùy chỉnh (có thể mất vài phút)...
docker build -t web_server .
if %errorlevel% neq 0 (
    echo [LỖI] Quá trình Build thất bại. Kiểm tra lại Dockerfile!
    pause
    exit /b 1
)

rem 5. Xây dựng danh sách dịch vụ cần khởi chạy
set SERVICES=web-app adminer

rem Kiểm tra nếu KHÔNG PHẢI là N hoặc n thì mới cài (Chấp nhận Y, y hoặc Enter)
if /i "%install_mysql%" neq "N" set SERVICES=%SERVICES% mysql
if /i "%install_mssql%" neq "N" set SERVICES=%SERVICES% sqlserver_db
if /i "%install_postgres%" neq "N" set SERVICES=%SERVICES% postgres
if /i "%install_mongo%" neq "N" set SERVICES=%SERVICES% mongodb
if /i "%install_redis%" neq "N" set SERVICES=%SERVICES% redis

echo.
echo [3/4] Đang khởi chạy các dịch vụ đã chọn (%SERVICES%)...
docker compose up -d %SERVICES%

rem 6. Kiểm tra trạng thái
echo.
echo [4/4] Kiểm tra trạng thái các dịch vụ...
echo.
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo ==============================================
echo    CHÚC MỪNG! HỆ THỐNG ĐÃ SẴN SÀNG
echo    Truy cập: http://localhost
echo    Code của ông nằm trong thư mục: .\www
echo ==============================================
pause