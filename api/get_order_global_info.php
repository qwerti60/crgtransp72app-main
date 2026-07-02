<?php
/**
 * GET: performer_id, order_id [, customer_id] — данные сделки из ordersglobal.
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$performerId = (int) ($_GET['performer_id'] ?? 0);
$orderId     = (int) ($_GET['order_id'] ?? 0);
$customerId  = trim((string) ($_GET['customer_id'] ?? ''));

if ($performerId <= 0 || $orderId <= 0) {
    http_response_code(400);
    echo json_encode(['error' => 'performer_id и order_id обязательны'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $customerFilter = '';
    $params = [
        ':performer_id' => $performerId,
        ':order_id' => $orderId,
    ];
    if ($customerId !== '' && $customerId !== '0') {
        $customerFilter = ' AND user_idok = :customer_id';
        $params[':customer_id'] = $customerId;
    }

    $sql = "SELECT user_id, order_id, user_idok, status, start_time, end_time
            FROM ordersglobal
            WHERE user_id = :performer_id AND order_id = :order_id{$customerFilter}
            ORDER BY id DESC
            LIMIT 1";

    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value, is_int($value) ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        echo json_encode(['found' => false], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode([
        'found'      => true,
        'user_id'    => $row['user_id'],
        'order_id'   => $row['order_id'],
        'user_idok'  => $row['user_idok'],
        'status'     => $row['status'],
        'start_time' => $row['start_time'],
        'end_time'   => $row['end_time'] ?? null,
    ], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
