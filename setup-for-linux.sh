#!/bin/bash

# --- Cấu hình màu sắc cho dễ nhìn ---
GREEN='\033;32m'
BLUE='\033;34m'
YELLOW='\033[1;33m'
RED='\033;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}   HỆ THỐNG TỰ ĐỘNG TRIỂN KHAI DOCKER DEV     ${NC}"
echo -e "${BLUE}==============================================${NC}"

# 1. Kiểm tra Docker đã cài chưa
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[LỖI] Docker chưa được cài đặt. Vui lòng cài Docker trước!${NC}"
    exit 1
fi

# 2. Hỏi người dùng chọn CSDL
echo -e "${YELLOW}Chọn các cơ sở dữ liệu bạn muốn cài đặt/kích hoạt:${NC}"
read -p "1. Cài đặt MySQL? (Y/n, mặc định Y): " install_mysql
read -p "2. Cài đặt SQL Server (MSSQL)? (Y/n, mặc định Y): " install_mssql
read -p "3. Cài đặt PostgreSQL? (Y/n, mặc định Y): " install_postgres
read -p "4. Cài đặt MongoDB? (Y/n, mặc định Y): " install_mongo

# 2.5 Hỏi mật khẩu dùng chung cho Admin tối cao (Bắt buộc nhập)
echo ""
echo -e "${YELLOW}==============================================${NC}"
echo -e "${YELLOW}    THIẾT LẬP MẬT KHẨU DÙNG CHUNG CHO ADMIN   ${NC}"
echo -e "${YELLOW}==============================================${NC}"

# Vòng lặp ép buộc nhập mật khẩu, không cho phép để trống
while true; do
    read -p "Nhập mật khẩu chung (Bắt buộc): " DEV_PASSWORD
    
    # Kiểm tra nếu biến DEV_PASSWORD bị trống
    if [ -z "$DEV_PASSWORD" ]; then
        echo -e "${RED}[CẢNH BÁO] Mật khẩu không được để trống! Vui lòng nhập lại.${NC}"
    else
        break # Đã nhập mật khẩu thành công, thoát vòng lặp
    fi
done

# Tự động ghi biến mật khẩu ra file .env để Docker Compose đọc
echo "DEV_PASSWORD=$DEV_PASSWORD" > .env

# 3. Đang dọn dẹp các Container cũ để tránh trùng tên/cổng
echo -e "${YELLOW}[1/4] Đang dọn dẹp các container cũ...${NC}"
docker compose down --remove-orphans &> /dev/null

# 4. Xây dựng Image PHP tùy chỉnh từ Dockerfile
echo -e "${YELLOW}[2/4] Đang build Image PHP tùy chỉnh (có thể mất vài phút)...${NC}"
docker build -t web_server .

if [ $? -ne 0 ]; then
    echo -e "${RED}[LỖI] Quá trình Build thất bại. Kiểm tra lại Dockerfile!${NC}"
    exit 1
fi

# 5. Xây dựng danh sách dịch vụ cần khởi chạy
SERVICES="web-app"

# Logic: Nếu câu trả lời KHÔNG PHẢI là N hoặc n thì tiến hành kích hoạt dịch vụ
if [[ ! "$install_mysql" =~ ^[Nn]$ ]]; then
    SERVICES="$SERVICES mysql"
fi
if [[ ! "$install_mssql" =~ ^[Nn]$ ]]; then
    SERVICES="$SERVICES sqlserver_db"
fi
if [[ ! "$install_postgres" =~ ^[Nn]$ ]]; then
    SERVICES="$SERVICES postgres"
fi
if [[ ! "$install_mongo" =~ ^[Nn]$ ]]; then
    SERVICES="$SERVICES mongodb"
fi

# 6. Khởi chạy các dịch vụ đã chọn
echo -e "${YELLOW}[3/4] Đang khởi chạy các dịch vụ đã chọn ($SERVICES)...${NC}"
docker compose up -d $SERVICES

# 7. Kiểm tra trạng thái cuối cùng
echo -e "${YELLOW}[4/4] Kiểm tra trạng thái các dịch vụ...${NC}"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}   CHÚC MỪNG! HỆ THỐNG ĐÃ SẴN SÀNG            ${NC}"
echo -e "${GREEN}   Truy cập: http://localhost                 ${NC}"
echo -e "${GREEN}   Code của ông nằm trong thư mục: ./www      ${NC}"
echo -e "${GREEN}==============================================${NC}"