<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';
$dbUser = $username;
$dbPassword = $password;
$dbName = $dbname;

$userId = isset($_POST['userId']) ? (int)$_POST['userId'] : 0;
$days = isset($_POST['days']) ? (int)$_POST['days'] : 30;
$days = $days > 0 ? $days : 30;

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Некорректный userId',
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

$selectSql = "SELECT `id`, `date`, `count` FROM `subscriptions` WHERE `iduser` = ? ORDER BY `id` DESC LIMIT 1";
$selectStmt = $mysqli->prepare($selectSql);
if (!$selectStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Ошибка подготовки запроса получения подписки',
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

$selectStmt->bind_param('i', $userId);
$selectStmt->execute();
$result = $selectStmt->get_result();
$row = $result ? $result->fetch_assoc() : null;
$selectStmt->close();

if (!$row || !isset($row['id'])) {
    echo json_encode([
        'success' => true,
        'deleted' => false,
        'count' => 0,
        'date' => null,
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

$subId = (int)$row['id'];
$currentCount = isset($row['count']) ? (int)$row['count'] : 0;
$newCount = max(0, $currentCount - 1);

if ($newCount === 0) {
    $deleteSql = "DELETE FROM `subscriptions` WHERE `id` = ?";
    $deleteStmt = $mysqli->prepare($deleteSql);
    if (!$deleteStmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Ошибка подготовки запроса удаления',
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

    $deleteStmt->bind_param('i', $subId);
    $ok = $deleteStmt->execute();
    $deleteStmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Не удалось удалить подписку',
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

    echo json_encode([
        'success' => true,
        'deleted' => true,
        'count' => 0,
        'date' => null,
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

$baseDate = new DateTime('now');
if (!empty($row['date'])) {
    $dbDate = DateTime::createFromFormat('Y-m-d', (string)$row['date']);
    if ($dbDate instanceof DateTime) {
        $baseDate = $dbDate;
    }
}
$newDate = $baseDate->modify('-' . $days . ' days')->format('Y-m-d');

$updateSql = "UPDATE `subscriptions` SET `count` = ?, `date` = ? WHERE `id` = ?";
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

$updateStmt->bind_param('isi', $newCount, $newDate, $subId);
$ok = $updateStmt->execute();
$updateStmt->close();

if (!$ok) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Не удалось обновить подписку',
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

echo json_encode([
    'success' => true,
    'deleted' => false,
    'count' => $newCount,
    'date' => $newDate,
], JSON_UNESCAPED_UNICODE);

$mysqli->close();
