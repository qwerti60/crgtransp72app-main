<?php
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

/**
 * Принятие / отказ по отклику.
 *
 * source:
 *   customer_order — заказчик на заявке (offer_data): idusers = id заявки, iduserp = исполнитель
 *   performer_ad   — исполнитель на объявлении (offer_dataf): idusers = id объявления, iduserp = заказчик
 *
 * action:
 *   accept — принять (offer_data.isp=1; offer_dataf.isp=1)
 *   refuse — отказ (DELETE offer_data; offer_dataf.isp=0)
 */
function crg_priem_source(): string
{
    $source = isset($_POST['source']) ? trim((string) $_POST['source']) : 'performer_ad';

    return $source === 'customer_order' ? 'customer_order' : 'performer_ad';
}

function crg_priem_action(): string
{
    $action = isset($_POST['action']) ? trim((string) $_POST['action']) : 'accept';

    return $action === 'refuse' ? 'refuse' : 'accept';
}

try {
    $conn = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    if (!isset($_POST['idusers'], $_POST['bd'], $_POST['iduserp'])) {
        throw new Exception('Отсутствуют обязательные параметры');
    }

    $adId = (int) $_POST['idusers'];
    $bd = (int) $_POST['bd'];
    $counterpartyId = (int) $_POST['iduserp'];
    $source = crg_priem_source();
    $action = crg_priem_action();

    if ($adId <= 0 || $bd <= 0 || $counterpartyId <= 0) {
        throw new Exception('Некорректные идентификаторы');
    }

    if ($source === 'customer_order') {
        if ($action === 'refuse') {
            require_once __DIR__ . '/include/offer_status.php';
            $stmt = $conn->prepare(
                'UPDATE offer_data SET isp = 0, status = :refused
                 WHERE iduser = :ad_id AND iduserp = :performer AND bd = :bd
                   AND (status = 0 OR status IS NULL)'
            );
            $refused = CRG_OFFER_STATUS_REFUSED;
            $stmt->execute([
                ':refused' => $refused,
                ':ad_id' => $adId,
                ':performer' => $counterpartyId,
                ':bd' => $bd,
            ]);
        } else {
            $stmtReset = $conn->prepare(
                'UPDATE offer_data SET isp = 0
                 WHERE iduser = :ad_id AND bd = :bd
                   AND (status = 0 OR status IS NULL)'
            );
            $stmtReset->execute([':ad_id' => $adId, ':bd' => $bd]);

            $stmtAccept = $conn->prepare(
                'UPDATE offer_data SET isp = 1
                 WHERE iduser = :ad_id AND iduserp = :performer AND bd = :bd
                   AND (status = 0 OR status IS NULL)'
            );
            $stmtAccept->execute([
                ':ad_id' => $adId,
                ':performer' => $counterpartyId,
                ':bd' => $bd,
            ]);

            if ($stmtAccept->rowCount() === 0) {
                throw new Exception('Отклик исполнителя не найден');
            }
        }
    } else {
        if ($action === 'refuse') {
            $stmt = $conn->prepare(
                'UPDATE offer_dataf SET isp = 0
                 WHERE iduser = :ad_id AND iduserp = :customer AND bd = :bd'
            );
            $stmt->execute([
                ':ad_id' => $adId,
                ':customer' => $counterpartyId,
                ':bd' => $bd,
            ]);
        } else {
            $stmt = $conn->prepare(
                'UPDATE offer_dataf SET isp = 1
                 WHERE iduser = :ad_id AND iduserp = :customer AND bd = :bd'
            );
            $stmt->execute([
                ':ad_id' => $adId,
                ':customer' => $counterpartyId,
                ':bd' => $bd,
            ]);

            if ($stmt->rowCount() === 0) {
                throw new Exception('Заявка заказчика не найдена');
            }
        }
    }

    try {
        require_once __DIR__ . '/include/deal_push.php';
        $event = $action === 'refuse' ? 'offer_rejected' : 'offer_accepted';
        // counterpartyId — кому уходит уведомление (вторая сторона сделки)
        crg_push_deal_event_safe($conn, $counterpartyId, $event, [
            'bd' => $bd,
            'ad_id' => $adId,
            'source' => $source,
            'action' => $action,
        ]);
    } catch (Throwable $e) {
        // ignore push errors
    }

    echo json_encode(['message' => 'Данные успешно обновлены'], JSON_UNESCAPED_UNICODE);
} catch (PDOException | Exception $e) {
    http_response_code(400);
    echo json_encode(['error' => 'Ошибка обработки запроса: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
