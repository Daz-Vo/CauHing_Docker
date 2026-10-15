@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo ==============================================
echo    HỆ THỐNG QUẢN LÝ ^& TRIỂN KHAI DOCKER DEV
echo ==============================================

rem 1. Kiểm tra Docker
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [LỖI] Docker chưa được cài đặt. Vui lòng cài Docker/Docker Desktop trước!
    pause
    exit /b 1
)

rem Đọc các biến mật khẩu hiện có trong .env nếu có
set "CURRENT_DEV_PW="
set "CURRENT_MYSQL_PW="
set "CURRENT_MSSQL_PW="
set "CURRENT_POSTGRES_PW="
set "CURRENT_MONGO_PW="

if exist .env (
    for /f "usebackq tokens=1,2 delims==" %%A in (".env") do (
        if "%%A"=="DEV_PASSWORD" set "CURRENT_DEV_PW=%%B"
        if "%%A"=="MYSQL_ROOT_PASSWORD" set "CURRENT_MYSQL_PW=%%B"
        if "%%A"=="MSSQL_SA_PASSWORD" set "CURRENT_MSSQL_PW=%%B"
        if "%%A"=="POSTGRES_PASSWORD" set "CURRENT_POSTGRES_PW=%%B"
        if "%%A"=="MONGO_INITDB_ROOT_PASSWORD" set "CURRENT_MONGO_PW=%%B"
    )
)

echo.
echo Vui lòng chọn chế độ hoạt động:
echo 1. Cài mới (Dọn dẹp toàn bộ dữ liệu ^& cài đặt lại từ đầu)
echo 2. Cài thêm / Cài lại dịch vụ
echo 3. Đổi mật khẩu dịch vụ
echo.
set /p MENU_CHOICE="Nhập lựa chọn của bạn (1/2/3): "

if "%MENU_CHOICE%"=="1" goto MODE_CLEAN_INSTALL
if "%MENU_CHOICE%"=="2" goto MODE_ADD_REINSTALL
if "%MENU_CHOICE%"=="3" goto MODE_CHANGE_PASSWORD

echo [LỖI] Lựa chọn không hợp lệ! Vui lòng chạy lại và chọn 1, 2 hoặc 3.
pause
exit /b 1

rem =======================================================
rem CHẾ ĐỘ 1: CÀI MỚI TOÀN BỘ / CÀI LẦN ĐẦU
rem =======================================================
:MODE_CLEAN_INSTALL
echo.
if exist .env (
    echo ==============================================
    echo    CẢNH BÁO: CHẾ ĐỘ CÀI MỚI TOÀN BỘ
    echo    Toàn bộ container và dữ liệu DB trong
    echo    thư mục .\data sẽ bị xóa sạch!
    echo ==============================================
    set /p confirm_clean="Bạn có chắc chắn muốn xóa hết để cài mới? (y/N): "
    if /i "!confirm_clean!" neq "Y" (
        echo Đã hủy thao tác cài mới.
        pause
        exit /b 0
    )
) else (
    echo ==============================================
    echo    BẠN ĐANG CÀI ĐẶT HỆ THỐNG LẦN ĐẦU TIÊN
    echo ==============================================
)

echo.
echo Chọn các cơ sở dữ liệu bạn muốn cài đặt/kích hoạt:
set /p install_mysql="1. Cài đặt MySQL? (Y/N, mặc định Y): "
set /p install_mssql="2. Cài đặt SQL Server (MSSQL)? (Y/N, mặc định Y): "
set /p install_postgres="3. Cài đặt PostgreSQL? (Y/N, mặc định Y): "
set /p install_mongo="4. Cài đặt MongoDB? (Y/N, mặc định Y): "
set /p install_redis="5. Cài đặt Redis? (Y/N, mặc định Y): "

if "%install_mysql%"=="" set install_mysql=Y
if "%install_mssql%"=="" set install_mssql=Y
if "%install_postgres%"=="" set install_postgres=Y
if "%install_mongo%"=="" set install_mongo=Y
if "%install_redis%"=="" set install_redis=Y

echo.
echo ==============================================
echo    THIẾT LẬP MẬT KHẨU DÙNG CHUNG CHO ADMIN
echo ==============================================
:ASK_PASSWORD_CLEAN
set "DEV_PASSWORD="
set /p DEV_PASSWORD="Nhập mật khẩu chung ban đầu (Bắt buộc): "
if "%DEV_PASSWORD%"=="" (
    echo [LỖI] Mật khẩu không được để trống! Vui lòng nhập lại.
    echo.
    goto ASK_PASSWORD_CLEAN
)

rem Ghi các biến riêng biệt vào file .env
(
echo DEV_PASSWORD=%DEV_PASSWORD%
echo MYSQL_ROOT_PASSWORD=%DEV_PASSWORD%
echo MSSQL_SA_PASSWORD=%DEV_PASSWORD%
echo POSTGRES_PASSWORD=%DEV_PASSWORD%
echo MONGO_INITDB_ROOT_PASSWORD=%DEV_PASSWORD%
) > .env

echo.
echo [1/5] Đang dọn dẹp các container cũ...
docker compose down --remove-orphans >nul 2>nul

echo [2/5] Đang dọn dẹp thư mục dữ liệu .\data...
if exist ".\data\mysql" rmdir /s /q ".\data\mysql" >nul 2>nul
if exist ".\data\sqlserver" rmdir /s /q ".\data\sqlserver" >nul 2>nul
if exist ".\data\postgres" rmdir /s /q ".\data\postgres" >nul 2>nul
if exist ".\data\mongo" rmdir /s /q ".\data\mongo" >nul 2>nul
mkdir .\data\mysql .\data\sqlserver .\data\postgres .\data\mongo >nul 2>nul

echo [3/5] Đang build Image PHP tùy chỉnh (có thể mất vài phút)...
docker build -t web_server .
if %errorlevel% neq 0 (
    echo [LỖI] Quá trình Build thất bại. Kiểm tra lại Dockerfile!
    pause
    exit /b 1
)

set SERVICES=web-app adminer
if /i "%install_mysql%" neq "N" set SERVICES=!SERVICES! mysql
if /i "%install_mssql%" neq "N" set SERVICES=!SERVICES! sqlserver_db
if /i "%install_postgres%" neq "N" set SERVICES=!SERVICES! postgres
if /i "%install_mongo%" neq "N" set SERVICES=!SERVICES! mongodb
if /i "%install_redis%" neq "N" set SERVICES=!SERVICES! redis

echo.
echo [4/5] Đang khởi chạy các dịch vụ đã chọn (!SERVICES!)...
docker compose up -d !SERVICES!

goto SHOW_STATUS


rem =======================================================
rem CHẾ ĐỘ 2: CÀI THÊM / CÀI LẠI
rem =======================================================
:MODE_ADD_REINSTALL
echo.
echo ==============================================
echo        CHẾ ĐỘ CÀI THÊM / CÀI LẠI DỊCH VỤ
echo ==============================================

rem Đảm bảo có DEV_PASSWORD và các biến trong .env
set "DEV_PASSWORD=%CURRENT_DEV_PW%"
if "%DEV_PASSWORD%"=="" (
    echo Chưa tìm thấy mật khẩu admin trong file .env.
    :ASK_PASSWORD_REINSTALL
    set /p DEV_PASSWORD="Nhập mật khẩu chung ban đầu (Bắt buộc): "
    if "!DEV_PASSWORD!"=="" (
        echo [LỖI] Mật khẩu không được để trống!
        goto ASK_PASSWORD_REINSTALL
    )
    (
    echo DEV_PASSWORD=!DEV_PASSWORD!
    echo MYSQL_ROOT_PASSWORD=!DEV_PASSWORD!
    echo MSSQL_SA_PASSWORD=!DEV_PASSWORD!
    echo POSTGRES_PASSWORD=!DEV_PASSWORD!
    echo MONGO_INITDB_ROOT_PASSWORD=!DEV_PASSWORD!
    ) > .env
)

docker image inspect web_server >nul 2>nul
if %errorlevel% neq 0 (
    echo Đang build image web_server...
    docker build -t web_server .
)

set "HAS_WEBAPP="
for /f "tokens=*" %%i in ('docker ps -a --filter "name=^/web-app$" --format "{{.Names}}"') do set "HAS_WEBAPP=%%i"
if "%HAS_WEBAPP%"=="" (
    echo Đang khởi chạy web-app ^& adminer...
    docker compose up -d web-app adminer
)

set "SERVICES_TO_UP="

rem --- 1. MySQL ---
set "EXISTS_MYSQL="
for /f "tokens=*" %%i in ('docker ps -a --filter "name=^/mysql_db$" --format "{{.Names}}"') do set "EXISTS_MYSQL=%%i"
if not "%EXISTS_MYSQL%"=="" (
    set /p c_mysql="MySQL ĐÃ TỒN TẠI. Bạn có muốn chọn MySQL không? (y/N): "
    if /i "!c_mysql!"=="Y" (
        echo [!] Cảnh báo: MySQL đã tồn tại.
        set /p rf_mysql="Bạn có muốn XÓA DỮ LIỆU và CÀI LẠI TỪ ĐẦU không? (y/N): "
        if /i "!rf_mysql!"=="Y" (
            echo Đang xóa container mysql_db và thư mục dữ liệu...
            docker compose rm -s -f -v mysql >nul 2>nul
            if exist ".\data\mysql" rmdir /s /q ".\data\mysql" >nul 2>nul
            mkdir .\data\mysql >nul 2>nul
        )
        set SERVICES_TO_UP=!SERVICES_TO_UP! mysql
    )
) else (
    set /p c_mysql="Cài đặt MySQL? (y/N): "
    if /i "!c_mysql!"=="Y" set SERVICES_TO_UP=!SERVICES_TO_UP! mysql
)

rem --- 2. SQL Server ---
set "EXISTS_MSSQL="
for /f "tokens=*" %%i in ('docker ps -a --filter "name=^/sqlserver_db$" --format "{{.Names}}"') do set "EXISTS_MSSQL=%%i"
if not "%EXISTS_MSSQL%"=="" (
    set /p c_mssql="SQL Server ĐÃ TỒN TẠI. Bạn có muốn chọn SQL Server không? (y/N): "
    if /i "!c_mssql!"=="Y" (
        echo [!] Cảnh báo: SQL Server đã tồn tại.
        set /p rf_mssql="Bạn có muốn XÓA DỮ LIỆU và CÀI LẠI TỪ ĐẦU không? (y/N): "
        if /i "!rf_mssql!"=="Y" (
            echo Đang xóa container sqlserver_db và thư mục dữ liệu...
            docker compose rm -s -f -v sqlserver_db >nul 2>nul
            if exist ".\data\sqlserver" rmdir /s /q ".\data\sqlserver" >nul 2>nul
            mkdir .\data\sqlserver >nul 2>nul
        )
        set SERVICES_TO_UP=!SERVICES_TO_UP! sqlserver_db
    )
) else (
    set /p c_mssql="Cài đặt SQL Server (MSSQL)? (y/N): "
    if /i "!c_mssql!"=="Y" set SERVICES_TO_UP=!SERVICES_TO_UP! sqlserver_db
)

rem --- 3. PostgreSQL ---
set "EXISTS_POSTGRES="
for /f "tokens=*" %%i in ('docker ps -a --filter "name=^/postgres_db$" --format "{{.Names}}"') do set "EXISTS_POSTGRES=%%i"
if not "%EXISTS_POSTGRES%"=="" (
    set /p c_pg="PostgreSQL ĐÃ TỒN TẠI. Bạn có muốn chọn PostgreSQL không? (y/N): "
    if /i "!c_pg!"=="Y" (
        echo [!] Cảnh báo: PostgreSQL đã tồn tại.
        set /p rf_pg="Bạn có muốn XÓA DỮ LIỆU và CÀI LẠI TỪ ĐẦU không? (y/N): "
        if /i "!rf_pg!"=="Y" (
            echo Đang xóa container postgres_db và thư mục dữ liệu...
            docker compose rm -s -f -v postgres >nul 2>nul
            if exist ".\data\postgres" rmdir /s /q ".\data\postgres" >nul 2>nul
            mkdir .\data\postgres >nul 2>nul
        )
        set SERVICES_TO_UP=!SERVICES_TO_UP! postgres
    )
) else (
    set /p c_pg="Cài đặt PostgreSQL? (y/N): "
    if /i "!c_pg!"=="Y" set SERVICES_TO_UP=!SERVICES_TO_UP! postgres
)

rem --- 4. MongoDB ---
set "EXISTS_MONGO="
for /f "tokens=*" %%i in ('docker ps -a --filter "name=^/mongo_db$" --format "{{.Names}}"') do set "EXISTS_MONGO=%%i"
if not "%EXISTS_MONGO%"=="" (
    set /p c_mg="MongoDB ĐÃ TỒN TẠI. Bạn có muốn chọn MongoDB không? (y/N): "
    if /i "!c_mg!"=="Y" (
        echo [!] Cảnh báo: MongoDB đã tồn tại.
        set /p rf_mg="Bạn có muốn XÓA DỮ LIỆU và CÀI LẠI TỪ ĐẦU không? (y/N): "
        if /i "!rf_mg!"=="Y" (
            echo Đang xóa container mongo_db và thư mục dữ liệu...
            docker compose rm -s -f -v mongodb >nul 2>nul
            if exist ".\data\mongo" rmdir /s /q ".\data\mongo" >nul 2>nul
            mkdir .\data\mongo >nul 2>nul
        )
        set SERVICES_TO_UP=!SERVICES_TO_UP! mongodb
    )
) else (
    set /p c_mg="Cài đặt MongoDB? (y/N): "
    if /i "!c_mg!"=="Y" set SERVICES_TO_UP=!SERVICES_TO_UP! mongodb
)

rem --- 5. Redis ---
set "EXISTS_REDIS="
for /f "tokens=*" %%i in ('docker ps -a --filter "name=^/redis_cache$" --format "{{.Names}}"') do set "EXISTS_REDIS=%%i"
if not "%EXISTS_REDIS%"=="" (
    set /p c_rd="Redis ĐÃ TỒN TẠI. Bạn có muốn chọn Redis không? (y/N): "
    if /i "!c_rd!"=="Y" (
        echo [!] Cảnh báo: Redis đã tồn tại.
        set /p rf_rd="Bạn có muốn CÀI LẠI Redis không? (y/N): "
        if /i "!rf_rd!"=="Y" (
            docker compose rm -s -f -v redis >nul 2>nul
        )
        set SERVICES_TO_UP=!SERVICES_TO_UP! redis
    )
) else (
    set /p c_rd="Cài đặt Redis? (y/N): "
    if /i "!c_rd!"=="Y" set SERVICES_TO_UP=!SERVICES_TO_UP! redis
)

if "%SERVICES_TO_UP%"=="" (
    echo.
    echo Không có dịch vụ nào được chọn để cài thêm/cài lại.
) else (
    echo.
    echo Đang khởi chạy các dịch vụ: %SERVICES_TO_UP%...
    docker compose up -d %SERVICES_TO_UP%
)

goto SHOW_STATUS


rem =======================================================
rem CHẾ ĐỘ 3: ĐỔI MẬT KHẨU
rem =======================================================
:MODE_CHANGE_PASSWORD
set "FALLBACK_PW=%CURRENT_DEV_PW%"
if "%FALLBACK_PW%"=="" set "FALLBACK_PW=admin"

echo.
echo ==============================================
echo           ĐỔI MẬT KHẨU DỊCH VỤ
echo ==============================================
echo Chọn dịch vụ cần đổi mật khẩu:
echo 1. MySQL (root)
echo 2. SQL Server / MSSQL (sa)
echo 3. PostgreSQL (postgres)
echo 4. MongoDB (root)
echo 5. Cập nhật lại biến mật khẩu bất kỳ trong file .env
echo 0. Quay lại / Thoát
echo.
set /p DB_CHOICE="Nhập lựa chọn của bạn (0-5): "

if "%DB_CHOICE%"=="0" exit /b 0

if "%DB_CHOICE%"=="1" (
    docker compose up -d mysql >nul 2>nul
    set "CURR_PW=%CURRENT_MYSQL_PW%"
    if "!CURR_PW!"=="" set "CURR_PW=%FALLBACK_PW%"

    set /p NEW_PW="Nhập mật khẩu MỚI cho MySQL root: "
    if "!NEW_PW!"=="" (
        echo [LỖI] Mật khẩu không được để trống!
        pause
        exit /b 1
    )
    echo Đang cập nhật mật khẩu cho MySQL...
    docker exec -i mysql_db mysql -u root -p"!CURR_PW!" -e "ALTER USER 'root'@'%%' IDENTIFIED BY '!NEW_PW!'; FLUSH PRIVILEGES;" 2>nul
    if !errorlevel! neq 0 (
        docker exec -i mysql_db mysql -u root -e "ALTER USER 'root'@'%%' IDENTIFIED BY '!NEW_PW!'; FLUSH PRIVILEGES;" 2>nul
    )
    if !errorlevel! equ 0 (
        call :UPDATE_ENV MYSQL_ROOT_PASSWORD !NEW_PW!
        echo [THÀNH CÔNG] Đã đổi mật khẩu MySQL sang: !NEW_PW! (đã lưu vào biến MYSQL_ROOT_PASSWORD trong .env)
    ) else (
        echo [LỖI] Đổi mật khẩu thất bại. Hãy kiểm tra container mysql_db có đang chạy không!
    )
    pause
    exit /b 0
)

if "%DB_CHOICE%"=="2" (
    docker compose up -d sqlserver_db >nul 2>nul
    set "CURR_PW=%CURRENT_MSSQL_PW%"
    if "!CURR_PW!"=="" set "CURR_PW=%FALLBACK_PW%"

    set /p NEW_PW="Nhập mật khẩu MỚI cho SQL Server sa (chữ hoa, thường, số, ký tự đặc biệt): "
    if "!NEW_PW!"=="" (
        echo [LỖI] Mật khẩu không được để trống!
        pause
        exit /b 1
    )
    echo Đang cập nhật mật khẩu cho SQL Server...
    docker exec -i sqlserver_db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "!CURR_PW!" -C -Q "ALTER LOGIN sa WITH PASSWORD = '!NEW_PW!';" 2>nul
    if !errorlevel! neq 0 (
        docker exec -i sqlserver_db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "!CURR_PW!" -Q "ALTER LOGIN sa WITH PASSWORD = '!NEW_PW!'; " 2>nul
    )
    if !errorlevel! equ 0 (
        call :UPDATE_ENV MSSQL_SA_PASSWORD !NEW_PW!
        echo [THÀNH CÔNG] Đã đổi mật khẩu SQL Server sang: !NEW_PW! (đã lưu vào biến MSSQL_SA_PASSWORD trong .env)
    ) else (
        echo [LỖI] Đổi mật khẩu thất bại. Kiểm tra container sqlserver_db hoặc quy tắc mật khẩu MSSQL!
    )
    pause
    exit /b 0
)

if "%DB_CHOICE%"=="3" (
    docker compose up -d postgres >nul 2>nul
    set /p NEW_PW="Nhập mật khẩu MỚI cho PostgreSQL postgres: "
    if "!NEW_PW!"=="" (
        echo [LỖI] Mật khẩu không được để trống!
        pause
        exit /b 1
    )
    echo Đang cập nhật mật khẩu cho PostgreSQL...
    docker exec -i postgres_db psql -U postgres -c "ALTER USER postgres WITH PASSWORD '!NEW_PW!';"
    if !errorlevel! equ 0 (
        call :UPDATE_ENV POSTGRES_PASSWORD !NEW_PW!
        echo [THÀNH CÔNG] Đã đổi mật khẩu PostgreSQL sang: !NEW_PW! (đã lưu vào biến POSTGRES_PASSWORD trong .env)
    ) else (
        echo [LỖI] Đổi mật khẩu PostgreSQL thất bại!
    )
    pause
    exit /b 0
)

if "%DB_CHOICE%"=="4" (
    docker compose up -d mongodb >nul 2>nul
    set "CURR_PW=%CURRENT_MONGO_PW%"
    if "!CURR_PW!"=="" set "CURR_PW=%FALLBACK_PW%"

    set /p NEW_PW="Nhập mật khẩu MỚI cho MongoDB root: "
    if "!NEW_PW!"=="" (
        echo [LỖI] Mật khẩu không được để trống!
        pause
        exit /b 1
    )
    echo Đang cập nhật mật khẩu cho MongoDB...
    docker exec -i mongo_db mongosh -u root -p "!CURR_PW!" --authenticationDatabase admin --eval "db.changeUserPassword('root', '!NEW_PW!')" 2>nul
    if !errorlevel! neq 0 (
        docker exec -i mongo_db mongo -u root -p "!CURR_PW!" --authenticationDatabase admin --eval "db.changeUserPassword('root', '!NEW_PW!')" 2>nul
    )
    if !errorlevel! equ 0 (
        call :UPDATE_ENV MONGO_INITDB_ROOT_PASSWORD !NEW_PW!
        echo [THÀNH CÔNG] Đã đổi mật khẩu MongoDB sang: !NEW_PW! (đã lưu vào biến MONGO_INITDB_ROOT_PASSWORD trong .env)
    ) else (
        echo [LỖI] Đổi mật khẩu MongoDB thất bại!
    )
    pause
    exit /b 0
)

if "%DB_CHOICE%"=="5" (
    echo Các biến mật khẩu trong hệ thống:
    echo 1. DEV_PASSWORD (Mật khẩu admin chung)
    echo 2. MYSQL_ROOT_PASSWORD (MySQL)
    echo 3. MSSQL_SA_PASSWORD (SQL Server)
    echo 4. POSTGRES_PASSWORD (PostgreSQL)
    echo 5. MONGO_INITDB_ROOT_PASSWORD (MongoDB)
    set /p var_ch="Chọn biến muốn cập nhật (1-5): "
    set "TARGET_KEY="
    if "!var_ch!"=="1" set "TARGET_KEY=DEV_PASSWORD"
    if "!var_ch!"=="2" set "TARGET_KEY=MYSQL_ROOT_PASSWORD"
    if "!var_ch!"=="3" set "TARGET_KEY=MSSQL_SA_PASSWORD"
    if "!var_ch!"=="4" set "TARGET_KEY=POSTGRES_PASSWORD"
    if "!var_ch!"=="5" set "TARGET_KEY=MONGO_INITDB_ROOT_PASSWORD"
    if "!TARGET_KEY!"=="" (
        echo [LỖI] Lựa chọn không hợp lệ!
        pause
        exit /b 1
    )
    set /p NEW_PW="Nhập mật khẩu mới cho !TARGET_KEY!: "
    if "!NEW_PW!"=="" (
        echo [LỖI] Mật khẩu không được để trống!
        pause
        exit /b 1
    )
    call :UPDATE_ENV !TARGET_KEY! !NEW_PW!
    echo [THÀNH CÔNG] Đã cập nhật !TARGET_KEY!=!NEW_PW! trong file .env
    pause
    exit /b 0
)

echo [LỖI] Lựa chọn không hợp lệ!
pause
exit /b 1


rem =======================================================
rem HÀM CẬP NHẬT BIẾN TRONG .ENV
rem =======================================================
:UPDATE_ENV
set "K=%1"
set "V=%2"
if not exist .env type nul > .env
powershell -Command "$c = Get-Content .env; if ($c -match '^%K%=') { $c -replace '^%K%=.*', '%K%=%V%' | Set-Content .env } else { Add-Content .env '%K%=%V%' }" >nul 2>nul
goto :eof


rem =======================================================
rem HIỂN THỊ TRẠNG THÁI CUỐI CÙNG
rem =======================================================
:SHOW_STATUS
echo.
echo [HOÀN TẤT] Kiểm tra trạng thái các dịch vụ...
echo.
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo ==============================================
echo    CHÚC MỪNG! HỆ THỐNG ĐÃ SẴN SÀNG
echo    Truy cập Web: http://localhost
echo    Quản lý DB (Adminer): http://localhost:8080
echo    Code của bạn nằm trong thư mục: .\www
echo ==============================================
pause