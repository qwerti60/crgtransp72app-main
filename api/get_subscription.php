<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$host = 'localhost';
$dbUser = 'u2395188_apps72';
$dbPassword = 'kR3iV2aA6gjU8nC9';
$dbName = 'u2395188_apps';

$userId = isset($_GET['userId']) ? (int)$_GET['userId'] : 0;

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode([
        'error' => 'Некорректный userId',
        'found' => false,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$mysqli = new mysqli($host, $dbUser, $dbPassword, $dbName);

if ($mysqli->connect_error) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Ошибка подключения к базе данных',
        'found' => false,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$mysqli->set_charset('utf8mb4');

$query = "SELECT `date`, `payment` FROM `subscriptions` WHERE `iduser` = ? ORDER BY `date` DESC, `id` DESC LIMIT 1";
$stmt = $mysqli->prepare($query);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Не удалось подготовить запрос',
        'found' => false,
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

$stmt->bind_param('i', $userId);
$stmt->execute();
$result = $stmt->get_result();
$row = $result ? $result->fetch_assoc() : null;

if ($row && !empty($row['date'])) {
    echo json_encode([
        'found' => true,
        'date' => $row['date'],
        'payment' => $row['payment'] ?? null,
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        'found' => false,
        'date' => null,
        'payment' => null,
    ], JSON_UNESCAPED_UNICODE);
}

$stmt->close();
$mysqli->close();
