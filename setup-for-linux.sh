#!/bin/bash

# --- Cấu hình màu sắc cho dễ nhìn ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}   HỆ THỐNG QUẢN LÝ & TRIỂN KHAI DOCKER DEV   ${NC}"
echo -e "${BLUE}==============================================${NC}"

# 1. Kiểm tra Docker đã cài chưa
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[LỖI] Docker chưa được cài đặt. Vui lòng cài Docker trước!${NC}"
    exit 1
fi

# Hàm kiểm tra container có tồn tại không
container_exists() {
    local cname="$1"
    [ "$(docker ps -a --filter "name=^/${cname}$" --format '{{.Names}}')" = "$cname" ]
}

# Hàm lấy giá trị biến từ file .env
get_env_val() {
    local key="$1"
    local default_val="$2"
    if [ -f .env ]; then
        local val
        val=$(grep -E "^${key}=" .env | cut -d '=' -f2-)
        if [ -n "$val" ]; then
            echo "$val"
            return
        fi
    fi
    echo "$default_val"
}

# Hàm ghi hoặc cập nhật một biến trong file .env
set_env_val() {
    local key="$1"
    local val="$2"
    touch .env
    if grep -qE "^${key}=" .env; then
        sed -i "s|^${key}=.*|${key}=${val}|" .env
    else
        echo "${key}=${val}" >> .env
    fi
}

# Hàm lấy mật khẩu hiện tại hoặc hỏi người dùng nhập mật khẩu chung ban đầu
get_or_ask_passwords() {
    local current_pw
    current_pw=$(get_env_val "DEV_PASSWORD" "")

    if [ -n "$current_pw" ]; then
        DEV_PASSWORD="$current_pw"
    else
        echo ""
        echo -e "${YELLOW}==============================================${NC}"
        echo -e "${YELLOW}    THIẾT LẬP MẬT KHẨU DÙNG CHUNG CHO ADMIN   ${NC}"
        echo -e "${YELLOW}==============================================${NC}"
        while true; do
            read -p "Nhập mật khẩu chung ban đầu (Bắt buộc): " DEV_PASSWORD
            if [ -z "$DEV_PASSWORD" ]; then
                echo -e "${RED}[CẢNH BÁO] Mật khẩu không được để trống! Vui lòng nhập lại.${NC}"
            else
                break
            fi
        done
        set_env_val "DEV_PASSWORD" "$DEV_PASSWORD"
        set_env_val "MYSQL_ROOT_PASSWORD" "$DEV_PASSWORD"
        set_env_val "MSSQL_SA_PASSWORD" "$DEV_PASSWORD"
        set_env_val "POSTGRES_PASSWORD" "$DEV_PASSWORD"
        set_env_val "MONGO_INITDB_ROOT_PASSWORD" "$DEV_PASSWORD"
    fi
}

# Hàm build web_server image nếu chưa có hoặc khi cài mới
build_web_image() {
    echo -e "${YELLOW}--> Kiểm tra / Build Image PHP web_server...${NC}"
    docker build -t web_server .
    if [ $? -ne 0 ]; then
        echo -e "${RED}[LỖI] Quá trình Build thất bại. Kiểm tra lại Dockerfile!${NC}"
        exit 1
    fi
}

# Hàm hiển thị trạng thái sau khi xong
show_status() {
    echo -e "${YELLOW}Đang kiểm tra trạng thái các dịch vụ...${NC}"
    echo ""
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}   HOÀN TẤT THAO TÁC!                         ${NC}"
    echo -e "${GREEN}   Truy cập Web: http://localhost             ${NC}"
    echo -e "${GREEN}   Quản lý DB (Adminer): http://localhost:8080 ${NC}"
    echo -e "${GREEN}   Thư mục mã nguồn: ./www                    ${NC}"
    echo -e "${GREEN}==============================================${NC}"
}

# MENU CHÍNH
echo -e "${CYAN}Vui lòng chọn chế độ hoạt động:${NC}"
echo "1. Cài mới (Dọn dẹp toàn bộ dữ liệu & cài đặt lại từ đầu)"
echo "2. Cài thêm / Cài lại dịch vụ"
echo "3. Đổi mật khẩu dịch vụ"
echo ""
read -p "Nhập lựa chọn của bạn (1/2/3): " MENU_CHOICE

case "$MENU_CHOICE" in
    1)
        # ==========================================
        # CHẾ ĐỘ 1: CÀI MỚI TOÀN BỘ / CÀI LẦN ĐẦU
        # ==========================================
        is_first_install=true
        if [ -f .env ]; then
            is_first_install=false
        elif container_exists "web-app" || container_exists "mysql_db" || container_exists "postgres_db"; then
            is_first_install=false
        fi

        echo ""
        if [ "$is_first_install" = true ]; then
            echo -e "${GREEN}==============================================${NC}"
            echo -e "${GREEN}   BẠN ĐANG CÀI ĐẶT HỆ THỐNG LẦN ĐẦU TIÊN     ${NC}"
            echo -e "${GREEN}==============================================${NC}"
        else
            echo -e "${RED}==============================================${NC}"
            echo -e "${RED}   CẢNH BÁO: CHẾ ĐỘ CÀI MỚI TOÀN BỘ           ${NC}"
            echo -e "${RED}   Toàn bộ container và dữ liệu DB trong      ${NC}"
            echo -e "${RED}   thư mục ./data sẽ bị xóa sạch!             ${NC}"
            echo -e "${RED}==============================================${NC}"
            read -p "Bạn có chắc chắn muốn xóa hết để cài mới? (y/N): " confirm_clean
            if [[ ! "$confirm_clean" =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Đã hủy thao tác cài mới.${NC}"
                exit 0
            fi
        fi

        echo -e "${YELLOW}Chọn các cơ sở dữ liệu bạn muốn cài đặt/kích hoạt:${NC}"
        read -p "1. Cài đặt MySQL? (Y/N, mặc định Y): " install_mysql
        read -p "2. Cài đặt SQL Server (MSSQL)? (Y/N, mặc định Y): " install_mssql
        read -p "3. Cài đặt PostgreSQL? (Y/N, mặc định Y): " install_postgres
        read -p "4. Cài đặt MongoDB? (Y/N, mặc định Y): " install_mongo
        read -p "5. Cài đặt Redis? (Y/N, mặc định Y): " install_redis

        echo ""
        echo -e "${YELLOW}==============================================${NC}"
        echo -e "${YELLOW}    THIẾT LẬP MẬT KHẨU DÙNG CHUNG CHO ADMIN   ${NC}"
        echo -e "${YELLOW}==============================================${NC}"
        while true; do
            read -p "Nhập mật khẩu chung ban đầu (Bắt buộc): " DEV_PASSWORD
            if [ -z "$DEV_PASSWORD" ]; then
                echo -e "${RED}[CẢNH BÁO] Mật khẩu không được để trống! Vui lòng nhập lại.${NC}"
            else
                break
            fi
        done

        # Ghi các biến riêng biệt vào .env
        cat <<EOF > .env
DEV_PASSWORD=$DEV_PASSWORD
MYSQL_ROOT_PASSWORD=$DEV_PASSWORD
MSSQL_SA_PASSWORD=$DEV_PASSWORD
POSTGRES_PASSWORD=$DEV_PASSWORD
MONGO_INITDB_ROOT_PASSWORD=$DEV_PASSWORD
EOF

        echo -e "${YELLOW}[1/5] Đang dọn dẹp các container cũ...${NC}"
        docker compose down --remove-orphans &> /dev/null

        echo -e "${YELLOW}[2/5] Đang dọn dẹp thư mục dữ liệu ./data...${NC}"
        rm -rf ./data/mysql ./data/sqlserver ./data/postgres ./data/mongo
        mkdir -p ./data/mysql ./data/sqlserver ./data/postgres ./data/mongo

        echo -e "${YELLOW}[3/5] Đang build Image PHP tùy chỉnh...${NC}"
        build_web_image

        SERVICES="web-app adminer"
        if [[ ! "$install_mysql" =~ ^[Nn]$ ]]; then SERVICES="$SERVICES mysql"; fi
        if [[ ! "$install_mssql" =~ ^[Nn]$ ]]; then SERVICES="$SERVICES sqlserver_db"; fi
        if [[ ! "$install_postgres" =~ ^[Nn]$ ]]; then SERVICES="$SERVICES postgres"; fi
        if [[ ! "$install_mongo" =~ ^[Nn]$ ]]; then SERVICES="$SERVICES mongodb"; fi
        if [[ ! "$install_redis" =~ ^[Nn]$ ]]; then SERVICES="$SERVICES redis"; fi

        echo -e "${YELLOW}[4/5] Đang khởi chạy các dịch vụ ($SERVICES)...${NC}"
        docker compose up -d $SERVICES

        echo -e "${YELLOW}[5/5] Cấp quyền cho thư mục ./www...${NC}"
        chmod -R 777 ./www 2>/dev/null || true

        show_status
        ;;

    2)
        # ==========================================
        # CHẾ ĐỘ 2: CÀI THÊM / CÀI LẠI
        # ==========================================
        echo ""
        echo -e "${BLUE}==============================================${NC}"
        echo -e "${BLUE}        CHẾ ĐỘ CÀI THÊM / CÀI LẠI DỊCH VỤ     ${NC}"
        echo -e "${BLUE}==============================================${NC}"

        get_or_ask_passwords

        # Kiểm tra web_server image và core services (web-app, adminer)
        if ! docker image inspect web_server &> /dev/null; then
            build_web_image
        fi
        if ! container_exists "web-app"; then
            echo -e "${YELLOW}Khởi động web-app & adminer...${NC}"
            docker compose up -d web-app adminer
        fi

        SERVICES_TO_UP=""

        handle_service() {
            local sname="$1"
            local cname="$2"
            local dname="$3"
            local datadir="$4"

            local prompt_msg="Cài đặt $dname? (Y/N, mặc định N): "
            if container_exists "$cname"; then
                prompt_msg="$dname ĐÃ TỒN TẠI. Bạn có muốn chọn dịch vụ này không? (Y/N, mặc định N): "
            fi

            read -p "$prompt_msg" choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                if container_exists "$cname"; then
                    echo -e "${RED}[!] Cảnh báo: $dname đã tồn tại (Container: $cname).${NC}"
                    read -p "Bạn có muốn XÓA DỮ LIỆU và CÀI LẠI TỪ ĐẦU không? (y/N): " confirm_reinstall
                    if [[ "$confirm_reinstall" =~ ^[Yy]$ ]]; then
                        echo -e "${YELLOW}Đang dừng và xóa container $cname...${NC}"
                        docker compose rm -s -f -v "$sname" &> /dev/null
                        if [ -n "$datadir" ] && [ -d "$datadir" ]; then
                            echo -e "${YELLOW}Đang xóa dữ liệu tại $datadir...${NC}"
                            rm -rf "$datadir"
                            mkdir -p "$datadir"
                        fi
                        SERVICES_TO_UP="$SERVICES_TO_UP $sname"
                    else
                        echo -e "${GREEN}Giữ nguyên $dname, chỉ khởi động lại nếu đang tắt.${NC}"
                        SERVICES_TO_UP="$SERVICES_TO_UP $sname"
                    fi
                else
                    echo -e "${GREEN}Thêm mới $dname...${NC}"
                    SERVICES_TO_UP="$SERVICES_TO_UP $sname"
                fi
            fi
        }

        echo ""
        echo -e "${YELLOW}Chọn các dịch vụ bạn muốn thao tác:${NC}"
        handle_service "mysql" "mysql_db" "MySQL" "./data/mysql"
        handle_service "sqlserver_db" "sqlserver_db" "SQL Server (MSSQL)" "./data/sqlserver"
        handle_service "postgres" "postgres_db" "PostgreSQL" "./data/postgres"
        handle_service "mongodb" "mongo_db" "MongoDB" "./data/mongo"
        handle_service "redis" "redis_cache" "Redis" ""

        if [ -z "$SERVICES_TO_UP" ]; then
            echo -e "${YELLOW}Không có dịch vụ nào được chọn để cài thêm/cài lại.${NC}"
        else
            echo ""
            echo -e "${YELLOW}Đang khởi chạy các dịch vụ: $SERVICES_TO_UP...${NC}"
            docker compose up -d $SERVICES_TO_UP
        fi

        show_status
        ;;

    3)
        # ==========================================
        # CHẾ ĐỘ 3: ĐỔI MẬT KHẨU
        # ==========================================
        echo ""
        echo -e "${BLUE}==============================================${NC}"
        echo -e "${BLUE}           ĐỔI MẬT KHẨU DỊCH VỤ               ${NC}"
        echo -e "${BLUE}==============================================${NC}"
        echo "Chọn dịch vụ cần đổi mật khẩu:"
        echo "1. MySQL (root)"
        echo "2. SQL Server / MSSQL (sa)"
        echo "3. PostgreSQL (postgres)"
        echo "4. MongoDB (root)"
        echo "5. Cập nhật lại biến mật khẩu bất kỳ trong file .env"
        echo "0. Quay lại / Thoát"
        echo ""
        read -p "Nhập lựa chọn của bạn (0-5): " db_choice

        fallback_pw=$(get_env_val "DEV_PASSWORD" "")

        case "$db_choice" in
            1)
                if ! container_exists "mysql_db"; then
                    echo -e "${RED}[LỖI] Container mysql_db chưa được tạo hoặc đang không tồn tại!${NC}"
                    exit 1
                fi
                docker compose up -d mysql &> /dev/null
                curr_my_pw=$(get_env_val "MYSQL_ROOT_PASSWORD" "$fallback_pw")

                read -p "Nhập mật khẩu MỚI cho MySQL root: " NEW_PW
                if [ -z "$NEW_PW" ]; then
                    echo -e "${RED}[LỖI] Mật khẩu không được để trống!${NC}"
                    exit 1
                fi
                echo -e "${YELLOW}Đang cập nhật mật khẩu cho MySQL...${NC}"
                docker exec -i mysql_db mysql -u root -p"$curr_my_pw" -e "ALTER USER 'root'@'%' IDENTIFIED BY '$NEW_PW'; FLUSH PRIVILEGES;" 2>/dev/null \
                || docker exec -i mysql_db mysql -u root -e "ALTER USER 'root'@'%' IDENTIFIED BY '$NEW_PW'; FLUSH PRIVILEGES;" 2>/dev/null
                if [ $? -eq 0 ]; then
                    set_env_val "MYSQL_ROOT_PASSWORD" "$NEW_PW"
                    echo -e "${GREEN}[THÀNH CÔNG] Đã đổi mật khẩu MySQL sang: $NEW_PW (đã lưu vào biến MYSQL_ROOT_PASSWORD trong .env)${NC}"
                else
                    echo -e "${RED}[LỖI] Đổi mật khẩu thất bại. Kiểm tra xem container có đang chạy không!${NC}"
                fi
                ;;
            2)
                if ! container_exists "sqlserver_db"; then
                    echo -e "${RED}[LỖI] Container sqlserver_db chưa được tạo hoặc đang không tồn tại!${NC}"
                    exit 1
                fi
                docker compose up -d sqlserver_db &> /dev/null
                curr_ms_pw=$(get_env_val "MSSQL_SA_PASSWORD" "$fallback_pw")

                read -p "Nhập mật khẩu MỚI cho SQL Server sa (Cần phức tạp: chữ hoa, chữ thường, số, ký tự đặc biệt): " NEW_PW
                if [ -z "$NEW_PW" ]; then
                    echo -e "${RED}[LỖI] Mật khẩu không được để trống!${NC}"
                    exit 1
                fi
                echo -e "${YELLOW}Đang cập nhật mật khẩu cho SQL Server...${NC}"
                docker exec -i sqlserver_db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$curr_ms_pw" -C -Q "ALTER LOGIN sa WITH PASSWORD = '$NEW_PW';" 2>/dev/null \
                || docker exec -i sqlserver_db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$curr_ms_pw" -Q "ALTER LOGIN sa WITH PASSWORD = '$NEW_PW';" 2>/dev/null
                if [ $? -eq 0 ]; then
                    set_env_val "MSSQL_SA_PASSWORD" "$NEW_PW"
                    echo -e "${GREEN}[THÀNH CÔNG] Đã đổi mật khẩu SQL Server sang: $NEW_PW (đã lưu vào biến MSSQL_SA_PASSWORD trong .env)${NC}"
                else
                    echo -e "${RED}[LỖI] Đổi mật khẩu thất bại. Vui lòng kiểm tra mật khẩu hiện tại hoặc độ phức tạp của mật khẩu mới!${NC}"
                fi
                ;;
            3)
                if ! container_exists "postgres_db"; then
                    echo -e "${RED}[LỖI] Container postgres_db chưa được tạo hoặc đang không tồn tại!${NC}"
                    exit 1
                fi
                docker compose up -d postgres &> /dev/null

                read -p "Nhập mật khẩu MỚI cho PostgreSQL (postgres): " NEW_PW
                if [ -z "$NEW_PW" ]; then
                    echo -e "${RED}[LỖI] Mật khẩu không được để trống!${NC}"
                    exit 1
                fi
                echo -e "${YELLOW}Đang cập nhật mật khẩu cho PostgreSQL...${NC}"
                docker exec -i postgres_db psql -U postgres -c "ALTER USER postgres WITH PASSWORD '$NEW_PW';"
                if [ $? -eq 0 ]; then
                    set_env_val "POSTGRES_PASSWORD" "$NEW_PW"
                    echo -e "${GREEN}[THÀNH CÔNG] Đã đổi mật khẩu PostgreSQL sang: $NEW_PW (đã lưu vào biến POSTGRES_PASSWORD trong .env)${NC}"
                else
                    echo -e "${RED}[LỖI] Đổi mật khẩu PostgreSQL thất bại!${NC}"
                fi
                ;;
            4)
                if ! container_exists "mongo_db"; then
                    echo -e "${RED}[LỖI] Container mongo_db chưa được tạo hoặc đang không tồn tại!${NC}"
                    exit 1
                fi
                docker compose up -d mongodb &> /dev/null
                curr_mg_pw=$(get_env_val "MONGO_INITDB_ROOT_PASSWORD" "$fallback_pw")

                read -p "Nhập mật khẩu MỚI cho MongoDB root: " NEW_PW
                if [ -z "$NEW_PW" ]; then
                    echo -e "${RED}[LỖI] Mật khẩu không được để trống!${NC}"
                    exit 1
                fi
                echo -e "${YELLOW}Đang cập nhật mật khẩu cho MongoDB...${NC}"
                docker exec -i mongo_db mongosh -u root -p "$curr_mg_pw" --authenticationDatabase admin --eval "db.changeUserPassword('root', '$NEW_PW')" 2>/dev/null \
                || docker exec -i mongo_db mongo -u root -p "$curr_mg_pw" --authenticationDatabase admin --eval "db.changeUserPassword('root', '$NEW_PW')" 2>/dev/null
                if [ $? -eq 0 ]; then
                    set_env_val "MONGO_INITDB_ROOT_PASSWORD" "$NEW_PW"
                    echo -e "${GREEN}[THÀNH CÔNG] Đã đổi mật khẩu MongoDB sang: $NEW_PW (đã lưu vào biến MONGO_INITDB_ROOT_PASSWORD trong .env)${NC}"
                else
                    echo -e "${RED}[LỖI] Đổi mật khẩu MongoDB thất bại!${NC}"
                fi
                ;;
            5)
                echo "Các biến mật khẩu trong hệ thống:"
                echo "1. DEV_PASSWORD (Mật khẩu admin chung)"
                echo "2. MYSQL_ROOT_PASSWORD (MySQL)"
                echo "3. MSSQL_SA_PASSWORD (SQL Server)"
                echo "4. POSTGRES_PASSWORD (PostgreSQL)"
                echo "5. MONGO_INITDB_ROOT_PASSWORD (MongoDB)"
                read -p "Chọn biến muốn cập nhật (1-5): " var_choice
                case "$var_choice" in
                    1) VAR_NAME="DEV_PASSWORD" ;;
                    2) VAR_NAME="MYSQL_ROOT_PASSWORD" ;;
                    3) VAR_NAME="MSSQL_SA_PASSWORD" ;;
                    4) VAR_NAME="POSTGRES_PASSWORD" ;;
                    5) VAR_NAME="MONGO_INITDB_ROOT_PASSWORD" ;;
                    *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}"; exit 1 ;;
                esac
                read -p "Nhập mật khẩu mới cho $VAR_NAME: " NEW_PW
                if [ -z "$NEW_PW" ]; then
                    echo -e "${RED}[LỖI] Mật khẩu không được để trống!${NC}"
                    exit 1
                fi
                set_env_val "$VAR_NAME" "$NEW_PW"
                echo -e "${GREEN}[THÀNH CÔNG] Đã cập nhật $VAR_NAME=$NEW_PW trong file .env${NC}"
                ;;
            0)
                echo "Thoát chương trình."
                exit 0
                ;;
            *)
                echo -e "${RED}Lựa chọn không hợp lệ!${NC}"
                exit 1
                ;;
        esac
        ;;

    *)
        echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng chạy lại script và chọn 1, 2 hoặc 3.${NC}"
        exit 1
        ;;
esac