<?php
header('Content-Type: application/json; charset=utf-8');

include 'databd.php';

/**
 * source:
 *   customer_order — исполнитель откликнулся на заявку заказчика (offer_data, order_id = id заявки).
 *   performer_ad   — заказчик откликнулся на объявление исполнителя (offer_dataf, order_id = id объявления).
 */
function crg_order_source(): string
{
    $source = isset($_POST['source']) ? trim((string) $_POST['source']) : 'customer_order';
    return $source === 'performer_ad' ? 'performer_ad' : 'customer_order';
}

function crg_json_running_order(array $row): void
{
    $startTime = $row['start_time'] ?? '';
    if ($startTime === '' || str_starts_with((string) $startTime, '0000-00-00')) {
        echo json_encode([
            'error' => 'Некорректное время начала в базе данных',
            'message' => 'Некорректное время начала заказа',
        ], JSON_UNESCAPED_UNICODE);
        return;
    }

    echo json_encode([
        'message' => 'Продолжается выполнение',
        'start_time' => $startTime,
    ], JSON_UNESCAPED_UNICODE);
}

function crg_json_terminal_order(array $row): void
{
    switch ($row['status']) {
        case 'отменен':
            echo json_encode([
                'message' => 'Заказ отменен',
                'cancel_time' => $row['cancel_time'] ?? null,
            ], JSON_UNESCAPED_UNICODE);
            break;
        case 'выполнен':
            $startTime = $row['start_time'] ?? '';
            $endTime = $row['end_time'] ?? '';
            $durationSeconds = 0;
            if ($startTime !== '' && $endTime !== '') {
                $st = strtotime((string) $startTime);
                $et = strtotime((string) $endTime);
                if ($st !== false && $et !== false) {
                    $durationSeconds = max(0, $et - $st);
                }
            }
            echo json_encode([
                'message' => 'Заказ выполнен',
                'start_time' => $startTime,
                'end_time' => $endTime,
                'duration' => $durationSeconds . ' секунд',
            ], JSON_UNESCAPED_UNICODE);
            break;
        default:
            echo json_encode([
                'message' => 'Неизвестный статус заказа',
            ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Активная или последняя сделка по исполнителю + order_id (+ заказчик).
 */
function crg_fetch_ordersglobal_deal(
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

/**
 * Сценарий 1 — как было: offer_data + ordersglobal по user_id + order_id заявки заказчика.
 */
function crg_handle_customer_order(
    PDO $pdo,
    int $performerId,
    string $orderId,
    string $startTime,
    string $userIdok,
    ?int $bd
): void {
    $row = crg_fetch_ordersglobal_deal($pdo, $performerId, $orderId, $userIdok);
    $recordExistsInOrdersGlobal = !empty($row);

    if ($recordExistsInOrdersGlobal && ($userIdok === '' || $userIdok === '0')) {
        $userIdok = (string) $row['user_idok'];
    }

    if (!$recordExistsInOrdersGlobal || $row['status'] !== 'выполняется' && !in_array($row['status'], ['выполнен', 'отменен'], true)) {
        // Нет сделки или последняя не в терминальном статусе — пробуем начать новую (сценарий 1).
        $hasTerminalDeal = $recordExistsInOrdersGlobal
            && in_array($row['status'], ['выполнен', 'отменен'], true);

        if ($hasTerminalDeal) {
            crg_json_terminal_order($row);
            return;
        }

        if ($userIdok === '' || $userIdok === '0') {
            throw new Exception('Параметр user_idok (id заказчика) обязателен для начала выполнения.');
        }

        $offerSql = 'SELECT * FROM offer_data
             WHERE iduserp = :iduserp AND iduser = :iduser AND status = 0 AND isp = 1';
        if ($bd !== null && $bd > 0) {
            $offerSql .= ' AND bd = :bd';
        }
        $offerSql .= ' LIMIT 1';

        $stmtCheckOfferData = $pdo->prepare($offerSql);
        $stmtCheckOfferData->bindValue(':iduserp', $performerId, PDO::PARAM_INT);
        $stmtCheckOfferData->bindValue(':iduser', $orderId, PDO::PARAM_STR);
        if ($bd !== null && $bd > 0) {
            $stmtCheckOfferData->bindValue(':bd', $bd, PDO::PARAM_INT);
        }
        $stmtCheckOfferData->execute();
        $offerRow = $stmtCheckOfferData->fetch(PDO::FETCH_ASSOC);

        if (!empty($offerRow)) {
            $stmtUpdateOfferData = $pdo->prepare('UPDATE offer_data SET status = 1 WHERE id = :id');
            $stmtUpdateOfferData->bindValue(':id', $offerRow['id'], PDO::PARAM_INT);
            $stmtUpdateOfferData->execute();

            $dealBd = ($bd !== null && $bd > 0) ? $bd : (int) ($offerRow['bd'] ?? 0);
            $stmtInsertOrdersGlobal = $pdo->prepare(
                "INSERT INTO ordersglobal
                 (user_id, order_id, deal_source, bd, user_idok, start_time, status, idoffer)
                 VALUES (:user_id, :order_id, 'customer_order', :bd, :user_idok, :start_time, 'выполняется', :idoffer)"
            );
            $stmtInsertOrdersGlobal->bindParam(':user_id', $performerId, PDO::PARAM_INT);
            $stmtInsertOrdersGlobal->bindParam(':order_id', $orderId, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindValue(':bd', $dealBd > 0 ? $dealBd : null, $dealBd > 0 ? PDO::PARAM_INT : PDO::PARAM_NULL);
            $stmtInsertOrdersGlobal->bindParam(':user_idok', $userIdok, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindParam(':start_time', $startTime, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindValue(':idoffer', (int) $offerRow['id'], PDO::PARAM_INT);
            $stmtInsertOrdersGlobal->execute();

            try {
                require_once __DIR__ . '/include/chat_core.php';
                crg_chat_on_ordersglobal_created($pdo, (int) $pdo->lastInsertId());
            } catch (Throwable $e) {
                // ignore chat hook errors
            }

            echo json_encode([
                'message' => 'Запись успешно создана',
            ], JSON_UNESCAPED_UNICODE);
        } else {
            echo json_encode([
                'message' => 'Предложение не принято заказчиком',
            ], JSON_UNESCAPED_UNICODE);
        }
        return;
    }

    switch ($row['status']) {
        case 'выполняется':
            crg_json_running_order($row);
            break;
        case 'отменен':
        case 'выполнен':
            crg_json_terminal_order($row);
            break;
        default:
            echo json_encode([
                'message' => 'Неизвестный статус заказа',
            ], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * Сценарий 2 — заявка на объявление исполнителя (offer_dataf).
 * Не подмешиваем старые сделки сценария 1 с тем же order_id.
 */
function crg_handle_performer_ad(
    PDO $pdo,
    int $performerId,
    string $adId,
    string $startTime,
    int $customerId,
    ?int $bd
): void {
    if ($customerId <= 0) {
        throw new Exception('Параметр user_idok (id заказчика) обязателен для начала выполнения.');
    }

    $stmtActive = $pdo->prepare(
        "SELECT * FROM ordersglobal
         WHERE user_id = :user_id
           AND order_id = :order_id
           AND user_idok = :user_idok
           AND status = 'выполняется'
         ORDER BY id DESC
         LIMIT 1"
    );
    $customerIdStr = (string) $customerId;
    $stmtActive->bindValue(':user_id', $performerId, PDO::PARAM_INT);
    $stmtActive->bindValue(':order_id', $adId, PDO::PARAM_STR);
    $stmtActive->bindParam(':user_idok', $customerIdStr, PDO::PARAM_STR);
    $stmtActive->execute();
    $activeRow = $stmtActive->fetch(PDO::FETCH_ASSOC);

    if (!empty($activeRow)) {
        crg_json_running_order($activeRow);
        return;
    }

    $offerSql = 'SELECT * FROM offer_dataf
         WHERE iduser = :ad_id AND iduserp = :customer AND isp = 1';
    if ($bd !== null && $bd > 0) {
        $offerSql .= ' AND bd = :bd';
    }
    $offerSql .= ' ORDER BY id DESC LIMIT 1';

    $stmtOffer = $pdo->prepare($offerSql);
    $stmtOffer->bindValue(':ad_id', (int) $adId, PDO::PARAM_INT);
    $stmtOffer->bindValue(':customer', $customerId, PDO::PARAM_INT);
    if ($bd !== null && $bd > 0) {
        $stmtOffer->bindValue(':bd', $bd, PDO::PARAM_INT);
    }
    $stmtOffer->execute();
    $offerRow = $stmtOffer->fetch(PDO::FETCH_ASSOC);

    if (empty($offerRow)) {
        echo json_encode([
            'message' => 'Предложение не принято заказчиком',
        ], JSON_UNESCAPED_UNICODE);
        return;
    }

    $dealBd = ($bd !== null && $bd > 0) ? $bd : (int) ($offerRow['bd'] ?? 0);
    $stmtInsert = $pdo->prepare(
        "INSERT INTO ordersglobal
         (user_id, order_id, deal_source, bd, user_idok, start_time, status, idoffer)
         VALUES (:user_id, :order_id, 'performer_ad', :bd, :user_idok, :start_time, 'выполняется', :idoffer)"
    );
    $stmtInsert->bindValue(':user_id', $performerId, PDO::PARAM_INT);
    $stmtInsert->bindValue(':order_id', $adId, PDO::PARAM_STR);
    $stmtInsert->bindValue(':bd', $dealBd > 0 ? $dealBd : null, $dealBd > 0 ? PDO::PARAM_INT : PDO::PARAM_NULL);
    $stmtInsert->bindParam(':user_idok', $customerIdStr, PDO::PARAM_STR);
    $stmtInsert->bindParam(':start_time', $startTime, PDO::PARAM_STR);
    $stmtInsert->bindValue(':idoffer', (int) $offerRow['id'], PDO::PARAM_INT);
    $stmtInsert->execute();

    try {
        require_once __DIR__ . '/include/chat_core.php';
        crg_chat_on_ordersglobal_created($pdo, (int) $pdo->lastInsertId());
    } catch (Throwable $e) {
        // ignore chat hook errors
    }

    echo json_encode([
        'message' => 'Запись успешно создана',
    ], JSON_UNESCAPED_UNICODE);
}

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $user_id = $_POST['user_id'] ?? '';
    $order_id = $_POST['order_id'] ?? '';
    $start_time = $_POST['start_time'] ?? '';
    $user_idok = $_POST['user_idok'] ?? '';
    $bd = isset($_POST['bd']) && $_POST['bd'] !== '' ? (int) $_POST['bd'] : null;
    $source = crg_order_source();

    if ($user_id === '' || $order_id === '' || $start_time === '') {
        throw new Exception('Параметры user_id, order_id или start_time отсутствуют!');
    }

    $performerId = (int) $user_id;
    $orderId = (string) $order_id;

    if ($source === 'performer_ad') {
        $customerId = ($user_idok !== '' && $user_idok !== '0') ? (int) $user_idok : 0;
        crg_handle_performer_ad($pdo, $performerId, $orderId, $start_time, $customerId, $bd);
    } else {
        crg_handle_customer_order($pdo, $performerId, $orderId, $start_time, $user_idok, $bd);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Ошибка при выполнении запроса к базе данных.',
        'details' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Возникла непредвиденная ошибка.',
        'details' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
