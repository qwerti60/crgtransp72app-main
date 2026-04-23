<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$host = 'localhost';
$dbUser = 'u2395188_apps72';
$dbPassword = 'kR3iV2aA6gjU8nC9';
$dbName = 'u2395188_apps';

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

$sql = "SELECT `days`, `price_rub` FROM `subscription_config` WHERE `is_active` = 1 ORDER BY `id` DESC LIMIT 1";
$stmt = $mysqli->prepare($sql);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Не удалось подготовить запрос',
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

$stmt->execute();
$result = $stmt->get_result();
$row = $result ? $result->fetch_assoc() : null;
$stmt->close();

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
