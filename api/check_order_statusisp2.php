<?php
/**
 * Заказчик: просмотр/продолжение выполнения заказа (ordersglobal).
 * POST user_id — id исполнителя, user_idok — id заказчика, order_id — id заявки или объявления.
 * source: customer_order (по умолчанию) | performer_ad
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';
require_once __DIR__ . '/include/datetime_mysql.php';

function crg_isp2_order_source(): string
{
    $source = isset($_POST['source']) ? trim((string) $_POST['source']) : 'customer_order';
    return $source === 'performer_ad' ? 'performer_ad' : 'customer_order';
}

function crg_isp2_json_status(array $row): void
{
    switch ($row['status']) {
        case 'выполняется':
            echo json_encode([
                'message'    => 'Продолжается выполнение',
                'start_time' => $row['start_time'],
            ], JSON_UNESCAPED_UNICODE);
            break;
        case 'отменен':
            echo json_encode([
                'message'     => 'Заказ отменен',
                'cancel_time' => $row['cancel_time'],
            ], JSON_UNESCAPED_UNICODE);
            break;
        case 'выполнен':
            $duration_seconds = strtotime($row['end_time']) - strtotime($row['start_time']);
            echo json_encode([
                'message'    => 'Заказ выполнен',
                'start_time' => $row['start_time'],
                'end_time'   => $row['end_time'],
                'duration'   => $duration_seconds . ' секунд',
            ], JSON_UNESCAPED_UNICODE);
            break;
        default:
            echo json_encode(['message' => 'Неизвестный статус заказа'], JSON_UNESCAPED_UNICODE);
    }
}

function crg_isp2_fetch_deal(
    PDO $pdo,
    int $performerId,
    string $orderId,
    string $userIdok
): ?array {
    $customerFilter = '';
    $params = [
        ':user_id' => $performerId,
        ':order_id' => $orderId,
    ];

    if ($userIdok !== '' && $userIdok !== '0') {
        $customerFilter = ' AND user_idok = :user_idok';
        $params[':user_idok'] = $userIdok;
    }

    $sqlActive = "SELECT * FROM ordersglobal
                  WHERE user_id = :user_id AND order_id = :order_id
                    AND status = 'выполняется'{$customerFilter}
                  ORDER BY id DESC LIMIT 1";
    $stmt = $pdo->prepare($sqlActive);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value, is_int($value) ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        return $row;
    }

    $sqlLatest = "SELECT * FROM ordersglobal
                  WHERE user_id = :user_id AND order_id = :order_id{$customerFilter}
                  ORDER BY id DESC LIMIT 1";
    $stmt = $pdo->prepare($sqlLatest);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value, is_int($value) ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row ?: null;
}

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $user_id    = $_POST['user_id'] ?? '';
    $order_id   = $_POST['order_id'] ?? '';
    $start_time = $_POST['start_time'] ?? '';
    $user_idok  = $_POST['user_idok'] ?? '';
    $source     = crg_isp2_order_source();

    if ($user_id === '' || $order_id === '' || $start_time === '') {
        throw new Exception('Параметры user_id, order_id или start_time отсутствуют!');
    }

    $start_time = crg_normalize_mysql_datetime((string) $start_time);

    $performerId = (int) $user_id;
    $orderId = (string) $order_id;

    if ($source === 'performer_ad') {
        if ($user_idok === '' || $user_idok === '0') {
            throw new Exception('Параметр user_idok (id заказчика) обязателен.');
        }

        $row = crg_isp2_fetch_deal($pdo, $performerId, $orderId, $user_idok);
        if (empty($row)) {
            echo json_encode(['message' => 'Заказ ещё не начат'], JSON_UNESCAPED_UNICODE);
            exit;
        }

        crg_isp2_json_status($row);
        exit;
    }

    $row = crg_isp2_fetch_deal($pdo, $performerId, $orderId, $user_idok);
    $recordExistsInOrdersGlobal = !empty($row);

    if ($recordExistsInOrdersGlobal && ($user_idok === '' || $user_idok === '0')) {
        $user_idok = (string) $row['user_idok'];
    }

    if (!$recordExistsInOrdersGlobal) {
        if ($user_idok === '' || $user_idok === '0') {
            throw new Exception('Параметр user_idok (id заказчика) обязателен.');
        }

        $stmtCheckOfferData = $pdo->prepare(
            'SELECT * FROM offer_data
             WHERE iduserp = :iduserp AND iduser = :iduser AND status = 0
             LIMIT 1'
        );
        $stmtCheckOfferData->bindValue(':iduserp', $user_id, PDO::PARAM_INT);
        $stmtCheckOfferData->bindValue(':iduser', $order_id, PDO::PARAM_STR);
        $stmtCheckOfferData->execute();
        $offerRow = $stmtCheckOfferData->fetch(PDO::FETCH_ASSOC);

        if (!empty($offerRow)) {
            $stmtUpdateOfferData = $pdo->prepare(
                'UPDATE offer_data SET status = 1 WHERE id = :id'
            );
            $stmtUpdateOfferData->bindValue(':id', $offerRow['id'], PDO::PARAM_INT);
            $stmtUpdateOfferData->execute();

            $stmtInsertOrdersGlobal = $pdo->prepare(
                'INSERT INTO ordersglobal
                 (user_id, order_id, user_idok, start_time, status, idoffer)
                 VALUES (:user_id, :order_id, :user_idok, :start_time, :status, :idoffer)'
            );
            $stmtInsertOrdersGlobal->bindValue(':user_id', $user_id, PDO::PARAM_INT);
            $stmtInsertOrdersGlobal->bindValue(':order_id', $order_id, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindValue(':user_idok', $user_idok, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindValue(':start_time', $start_time, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindValue(':status', 'выполняется', PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindValue(':idoffer', $offerRow['id'], PDO::PARAM_INT);
            $stmtInsertOrdersGlobal->execute();

            try {
                require_once __DIR__ . '/include/chat_core.php';
                crg_chat_on_ordersglobal_created($pdo, (int) $pdo->lastInsertId());
            } catch (Throwable $e) {
                // ignore chat hook errors
            }

            echo json_encode([
                'message' => 'Запись успешно создана',
                'start_time' => $start_time,
            ], JSON_UNESCAPED_UNICODE);
        } else {
            echo json_encode(['message' => 'Выполняется другим исполнителем'], JSON_UNESCAPED_UNICODE);
        }
    } else {
        crg_isp2_json_status($row);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error'   => 'Ошибка при выполнении запроса к базе данных.',
        'details' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error'   => 'Возникла непредвиденная ошибка.',
        'details' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
