<?php
echo "<h2>Kiểm tra kết nối Database (Bản cập nhật):</h2>";

$dev_password = getenv('DEV_PASSWORD') ?: 'root'; // Fallback nếu không có

// 1. Kiểm tra MySQL (Kết nối vào db 'mysql' có sẵn)
try {
    $mysql = new PDO("mysql:host=mysql;dbname=mysql", "root", $dev_password);
    echo "✅ MySQL: Kết nối thành công!<br>";
} catch (Exception $e) { echo "❌ MySQL: Lỗi - " . $e->getMessage() . "<br>"; }

// 2. Kiểm tra PostgreSQL (Kết nối vào db 'postgres' có sẵn)
try {
    $pgsql = new PDO("pgsql:host=postgres;dbname=postgres", "postgres", $dev_password);
    echo "✅ PostgreSQL: Kết nối thành công!<br>";
} catch (Exception $e) { echo "❌ PostgreSQL: Lỗi - " . $e->getMessage() . "<br>"; }

// 3. Kiểm tra SQL Server (Thêm TrustServerCertificate để sửa lỗi SSL)
try {
    // Lưu ý: TrustServerCertificate=1 là bắt buộc cho môi trường Docker/Local
    $sqlsrv = new PDO("sqlsrv:Server=sqlserver;Database=master;TrustServerCertificate=1", "sa", $dev_password);
    echo "✅ SQL Server: Kết nối thành công!<br>";
} catch (Exception $e) { echo "❌ SQL Server: Lỗi - " . $e->getMessage() . "<br>"; }

// 4. Kiểm tra MongoDB
try {
    $mongo = new MongoDB\Driver\Manager("mongodb://root:" . urlencode($dev_password) . "@mongodb:27017");
    echo "✅ MongoDB: Driver đã sẵn sàng!<br>";
} catch (Exception $e) { echo "❌ MongoDB: Lỗi - " . $e->getMessage() . "<br>"; }
?>