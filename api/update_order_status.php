<?php
header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';

function crg_to_mysql_datetime(?string $raw): string
{
    if ($raw === null || trim($raw) === '') {
        return date('Y-m-d H:i:s');
    }
    try {
        return (new DateTime($raw))->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        return date('Y-m-d H:i:s');
    }
}

/**
 * Активная сделка или последняя по паре исполнитель + заказ (+ заказчик).
 */
function crg_find_ordersglobal_for_update(
    PDO $pdo,
    int $performerId,
    string $orderId,
    string $customerId
): ?array {
    $customerFilter = '';
    $params = [
        ':user_id' => $performerId,
        ':order_id' => $orderId,
    ];

    if ($customerId !== '' && $customerId !== '0') {
        $customerFilter = ' AND user_idok = :user_idok';
        $params[':user_idok'] = $customerId;
    }

    $sqlActive = "SELECT * FROM ordersglobal
                  WHERE user_id = :user_id AND order_id = :order_id
                    AND status IN ('выполняется', 'в_пути'){$customerFilter}
                  ORDER BY id DESC
                  LIMIT 1";
    $stmt = $pdo->prepare($sqlActive);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value, is_int($value) ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        return $row;
    }

    return null;
}

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $rawInput = file_get_contents('php://input');
    $requestData = json_decode($rawInput, true);
    if (!is_array($requestData)) {
        throw new Exception('Некорректное тело запроса.');
    }

    foreach (['user_id', 'order_id', 'status'] as $param) {
        if (!isset($requestData[$param]) || $requestData[$param] === '' || $requestData[$param] === null) {
            throw new Exception("Параметр '$param' отсутствует или пуст.");
        }
    }

    $user_id = (int) $requestData['user_id'];
    $order_id = (string) $requestData['order_id'];
    $new_status = (string) $requestData['status'];
    $customer_id = isset($requestData['user_idok']) ? trim((string) $requestData['user_idok']) : '';

    $activeRow = crg_find_ordersglobal_for_update($pdo, $user_id, $order_id, $customer_id);
    if ($activeRow === null) {
        // Без id заказчика — последняя выполняющаяся сделка (обратная совместимость).
        if ($customer_id === '' || $customer_id === '0') {
            $stmt = $pdo->prepare(
                "SELECT * FROM ordersglobal
                 WHERE user_id = :user_id AND order_id = :order_id AND status IN ('выполняется', 'в_пути')
                 ORDER BY id DESC
                 LIMIT 1"
            );
            $stmt->bindValue(':user_id', $user_id, PDO::PARAM_INT);
            $stmt->bindValue(':order_id', $order_id, PDO::PARAM_STR);
            $stmt->execute();
            $activeRow = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
        }
    }

    if ($activeRow === null) {
        throw new Exception('Активный заказ для завершения не найден.');
    }

    $orderGlobalId = (int) $activeRow['id'];
    $endTime = crg_to_mysql_datetime($requestData['current_date_time'] ?? null);
    $cancelTime = $endTime;

    if ($new_status === 'выполнен') {
        $stmt = $pdo->prepare(
            "UPDATE ordersglobal
             SET status = 'выполнен', end_time = :end_time
             WHERE id = :id AND status IN ('выполняется', 'в_пути')"
        );
        $stmt->bindValue(':end_time', $endTime, PDO::PARAM_STR);
        $stmt->bindValue(':id', $orderGlobalId, PDO::PARAM_INT);
        $stmt->execute();
    } elseif ($new_status === 'отменен') {
        $stmt = $pdo->prepare(
            "UPDATE ordersglobal
             SET status = 'отменен', cancel_time = :cancel_time
             WHERE id = :id AND status IN ('выполняется', 'в_пути')"
        );
        $stmt->bindValue(':cancel_time', $cancelTime, PDO::PARAM_STR);
        $stmt->bindValue(':id', $orderGlobalId, PDO::PARAM_INT);
        $stmt->execute();
    } else {
        $stmt = $pdo->prepare(
            "UPDATE ordersglobal SET status = :status WHERE id = :id AND status IN ('выполняется', 'в_пути')"
        );
        $stmt->bindValue(':status', $new_status, PDO::PARAM_STR);
        $stmt->bindValue(':id', $orderGlobalId, PDO::PARAM_INT);
        $stmt->execute();
    }

    if ($stmt->rowCount() === 0) {
        throw new Exception('Не удалось обновить статус заказа.');
    }

    try {
        require_once __DIR__ . '/include/chat_core.php';
        crg_chat_on_ordersglobal_status($pdo, $orderGlobalId, $new_status);
    } catch (Throwable $e) {
        // ignore chat hook errors
    }

    $selectStmt = $pdo->prepare('SELECT * FROM ordersglobal WHERE id = :id');
    $selectStmt->bindValue(':id', $orderGlobalId, PDO::PARAM_INT);
    $selectStmt->execute();
    $row = $selectStmt->fetch(PDO::FETCH_ASSOC);

    if ($new_status === 'отменен') {
        echo json_encode([
            'message' => 'Заказ отменён.',
            'cancel_time' => $row['cancel_time'] ?? null,
        ], JSON_UNESCAPED_UNICODE);
    } elseif ($new_status === 'выполнен') {
        $startTime = strtotime((string) ($row['start_time'] ?? ''));
        $endTimeTs = strtotime((string) ($row['end_time'] ?? ''));
        $durationSeconds = ($startTime !== false && $endTimeTs !== false)
            ? max(0, $endTimeTs - $startTime)
            : 0;

        echo json_encode([
            'message' => 'Заказ выполнен.',
            'start_time' => $row['start_time'],
            'end_time' => $row['end_time'],
            'duration_seconds' => $durationSeconds,
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(['message' => 'Обновлён статус заказа'], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка базы данных.', 'details' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
