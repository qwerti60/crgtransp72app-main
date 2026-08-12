<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';
$dbUser = $username;
$dbPassword = $password;
$dbName = $dbname;

$mysqli = new mysqli($host, $dbUser, $dbPassword, $dbName);
if ($mysqli->connect_error) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Ошибка подключения к базе данных',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$mysqli->set_charset('utf8mb4');

// Предпочитаем пакет «month», если таблицы пакетов уже развёрнуты.
$row = null;
$pkgRes = @$mysqli->query(
    "SELECT `days`, `price_rub` FROM `subscription_packages`
     WHERE `is_active` = 1 AND `code` = 'month'
     ORDER BY `id` ASC LIMIT 1"
);
if ($pkgRes) {
    $row = $pkgRes->fetch_assoc() ?: null;
}

if ($row === null) {
    $sql = "SELECT `days`, `price_rub` FROM `subscription_config` WHERE `is_active` = 1 ORDER BY `id` DESC LIMIT 1";
    $stmt = $mysqli->prepare($sql);
    if ($stmt) {
        $stmt->execute();
        $result = $stmt->get_result();
        $row = $result ? $result->fetch_assoc() : null;
        $stmt->close();
    }
}

if ($row && isset($row['days'], $row['price_rub'])) {
    $days = (int)$row['days'];
    $priceRub = (int)$row['price_rub'];
    echo json_encode([
        'success' => true,
        'days' => $days,
        'price_rub' => $priceRub,
        'amount_kopecks' => $priceRub * 100,
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        'success' => true,
        'days' => 30,
        'price_rub' => 300,
        'amount_kopecks' => 30000,
    ], JSON_UNESCAPED_UNICODE);
}

$mysqli->close();
