FROM php:8.2-apache

# Cập nhật và cài đặt các thư viện hệ thống cần thiết
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gnupg2 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 1. Cài đặt Driver cho MySQL và PostgreSQL
RUN docker-php-ext-install mysqli pdo pdo_mysql pdo_pgsql

# 2. Cài đặt Driver cho Microsoft SQL Server (Cách mới thay cho apt-key)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 unixodbc-dev \
    && pecl install sqlsrv-5.12.0 pdo_sqlsrv-5.12.0 \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv

# 3. Cài đặt Driver cho MongoDB
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Kích hoạt mod_rewrite cho Apache
RUN a2enmod rewrite

WORKDIR /var/www/html