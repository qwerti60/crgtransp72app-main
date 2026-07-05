<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$host = 'localhost';
$dbUser = 'u2395188_apps72';
$dbPassword = 'kR3iV2aA6gjU8nC9';
$dbName = 'u2395188_apps';

$userId = isset($_POST['userId']) ? (int)$_POST['userId'] : 0;
$orderId = isset($_POST['orderId']) ? trim((string)$_POST['orderId']) : '';
$days = isset($_POST['days']) ? (int)$_POST['days'] : 30;
$days = $days > 0 ? $days : 30;
$amountRub = isset($_POST['amountRub']) ? (int)$_POST['amountRub'] : 0;

if ($userId <= 0 || $orderId === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Некорректные параметры userId/orderId',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

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

$checkSql = "SELECT `id`, `date` FROM `subscriptions` WHERE `iduser` = ? ORDER BY `id` DESC LIMIT 1";
$checkStmt = $mysqli->prepare($checkSql);
if (!$checkStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Ошибка подготовки запроса проверки',
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

$checkStmt->bind_param('i', $userId);
$checkStmt->execute();
$checkResult = $checkStmt->get_result();
$existingRow = $checkResult ? $checkResult->fetch_assoc() : null;
$checkStmt->close();

$baseDate = new DateTime('now');
if ($existingRow && !empty($existingRow['date'])) {
    $existingDate = DateTime::createFromFormat('Y-m-d', (string)$existingRow['date']);
    if ($existingDate instanceof DateTime) {
        $baseDate = $existingDate;
    }
}

$newDate = $baseDate->modify('+' . $days . ' days')->format('Y-m-d');

if ($existingRow && isset($existingRow['id'])) {
    $subId = (int)$existingRow['id'];
    $updateSql = "UPDATE `subscriptions` SET `date` = ?, `payment` = ?, `count` = COALESCE(`count`, 0) + 1 WHERE `id` = ?";
    $updateStmt = $mysqli->prepare($updateSql);
    if (!$updateStmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Ошибка подготовки запроса обновления',
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

    $updateStmt->bind_param('ssi', $newDate, $orderId, $subId);
    $ok = $updateStmt->execute();
    $updateStmt->close();
} else {
    $insertSql = "INSERT INTO `subscriptions` (`iduser`, `date`, `payment`, `count`) VALUES (?, ?, ?, 1)";
    $insertStmt = $mysqli->prepare($insertSql);
    if (!$insertStmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Ошибка подготовки запроса создания',
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

    $insertStmt->bind_param('iss', $userId, $newDate, $orderId);
    $ok = $insertStmt->execute();
    $insertStmt->close();
}

if (!$ok) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Не удалось сохранить подписку',
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

require_once __DIR__ . '/include/performer_finances.php';
try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbName};charset=utf8mb4",
        $dbUser,
        $dbPassword,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    crg_finances_log_subscription_payment($pdo, $userId, $orderId, $amountRub, $days, $newDate);
} catch (Throwable $e) {
    // Журнал оплат не блокирует успешное продление подписки.
}

echo json_encode([
    'success' => true,
    'date' => $newDate,
    'payment' => $orderId,
], JSON_UNESCAPED_UNICODE);

$mysqli->close();
