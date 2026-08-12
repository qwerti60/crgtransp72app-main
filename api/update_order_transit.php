<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/databd.php';
require_once __DIR__ . '/include/deal_push.php';

function crg_transit_to_mysql_datetime(?string $raw): ?string
{
    if ($raw === null || trim($raw) === '') {
        return null;
    }
    try {
        return (new DateTime($raw))->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        return null;
    }
}

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $rawInput = file_get_contents('php://input');
    $requestData = json_decode($rawInput, true);
    if (!is_array($requestData)) {
        throw new Exception('Некорректное тело запроса.');
    }

    foreach (['user_id', 'order_id'] as $param) {
        if (empty($requestData[$param])) {
            throw new Exception("Параметр '$param' обязателен.");
        }
    }

    $user_id = (int) $requestData['user_id'];
    $order_id = (string) $requestData['order_id'];
    $customer_id = isset($requestData['user_idok']) ? trim((string) $requestData['user_idok']) : '';
    $etaRaw = isset($requestData['eta_at']) ? (string) $requestData['eta_at'] : '';
    $lat = isset($requestData['lat']) ? (float) $requestData['lat'] : null;
    $lng = isset($requestData['lng']) ? (float) $requestData['lng'] : null;

    $customerFilter = '';
    $params = [':user_id' => $user_id, ':order_id' => $order_id];
    if ($customer_id !== '' && $customer_id !== '0') {
        $customerFilter = ' AND user_idok = :user_idok';
        $params[':user_idok'] = $customer_id;
    }

    $sql = "SELECT * FROM ordersglobal
            WHERE user_id = :user_id AND order_id = :order_id
              AND status = 'выполняется'{$customerFilter}
            ORDER BY id DESC LIMIT 1";
    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value, is_int($value) ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        throw new Exception('Активная сделка не найдена.');
    }

    $orderGlobalId = (int) $row['id'];
    $now = date('Y-m-d H:i:s');
    $eta = crg_transit_to_mysql_datetime($etaRaw);

    $upd = $pdo->prepare(
        "UPDATE ordersglobal
         SET status = 'в_пути', in_transit_at = :now, eta_at = :eta,
             transit_lat = :lat, transit_lng = :lng
         WHERE id = :id AND status = 'выполняется'"
    );
    $upd->bindValue(':now', $now, PDO::PARAM_STR);
    $upd->bindValue(':eta', $eta, $eta === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
    $upd->bindValue(':lat', $lat, $lat === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
    $upd->bindValue(':lng', $lng, $lng === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
    $upd->bindValue(':id', $orderGlobalId, PDO::PARAM_INT);
    $upd->execute();

    if ($upd->rowCount() === 0) {
        throw new Exception('Не удалось обновить статус.');
    }

    $customerUserId = (int) ($row['user_idok'] ?? 0);
    if ($customerUserId > 0) {
        crg_push_deal_event_safe($pdo, $customerUserId, 'in_transit', [
            'order_id' => $order_id,
            'performer_id' => (string) $user_id,
            'eta_at' => $eta ?? '',
        ]);
    }

    echo json_encode([
        'message' => 'Статус «в пути» установлен',
        'status' => 'в_пути',
        'in_transit_at' => $now,
        'eta_at' => $eta,
        'transit_lat' => $lat,
        'transit_lng' => $lng,
    ], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка базы данных.', 'details' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
