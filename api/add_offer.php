<?php
/**
 * Исполнитель: предложение услуги по объявлению заказчика (таблица offer_data).
 * Заказчик / экран «Предложить заказ» — add_offerzakaz.php → offer_dataf (см. OfferScreen2).
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$pdo = new PDO(
    "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
    $username,
    $password,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$input   = json_decode(file_get_contents('php://input'), true) ?: $_POST;
$cena    = $input['cena'] ?? '';
$about   = $input['about'] ?? '';
$iduserp = $input['iduserp'] ?? '';
$iduser  = $input['iduser'] ?? '';
$bd      = $input['bd'] ?? '';

require_once __DIR__ . '/include/offer_validation.php';
require_once __DIR__ . '/include/offer_status.php';

$performerId = (int) $iduserp;
$orderId = (int) $iduser;
$bdInt = (int) $bd;

if ($performerId <= 0 || $orderId <= 0 || $bdInt <= 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Invalid parameters'], JSON_UNESCAPED_UNICODE);
    exit;
}

$orderOwner = crg_customer_order_owner_id($pdo, $orderId, $bdInt);
if ($orderOwner === null) {
    http_response_code(404);
    echo json_encode(['status' => 'error', 'message' => 'Order not found'], JSON_UNESCAPED_UNICODE);
    exit;
}
if ($orderOwner === $performerId) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Cannot offer on your own order'], JSON_UNESCAPED_UNICODE);
    exit;
}

$sqlExists = 'SELECT status
              FROM offer_data
              WHERE iduserp = ? AND iduser = ? AND bd = ?
                AND status IN (?, ?)
              ORDER BY id DESC
              LIMIT 1';
$active = CRG_OFFER_STATUS_ACTIVE;
$refused = CRG_OFFER_STATUS_REFUSED;
$stmt = $pdo->prepare($sqlExists);
$stmt->execute([$iduserp, $iduser, $bd, $active, $refused]);
$existingStatus = $stmt->fetchColumn();

if ($existingStatus !== false) {
    $existingStatus = (int) $existingStatus;
    if ($existingStatus === CRG_OFFER_STATUS_REFUSED) {
        http_response_code(403);
        echo json_encode([
            'status' => 'error',
            'message' => 'Заказчик отказался от предложения. Удалите его в разделе «Предложения».',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $sqlUpdate = 'UPDATE offer_data
                  SET cena = ?, about = ?
                  WHERE iduserp = ? AND iduser = ? AND bd = ? AND status = ?';
    $pdo->prepare($sqlUpdate)->execute([
        $cena,
        $about,
        $iduserp,
        $iduser,
        $bd,
        CRG_OFFER_STATUS_ACTIVE,
    ]);

    echo json_encode(['status' => 'updated', 'message' => 'Data updated successfully']);
} else {
    $sqlInsert = 'INSERT INTO offer_data (cena, about, iduserp, iduser, bd)
                  VALUES (?, ?, ?, ?, ?)';
    $pdo->prepare($sqlInsert)->execute([$cena, $about, $iduserp, $iduser, $bd]);
    $offerId = (int) $pdo->lastInsertId();
    try {
        require_once __DIR__ . '/include/chat_core.php';
        crg_chat_on_offer_data($pdo, $offerId, (int) $iduserp, (int) $iduser, (int) $bd);
    } catch (Throwable $e) {
        // ignore chat hook errors
    }
    try {
        require_once __DIR__ . '/include/deal_push.php';
        crg_push_deal_event_safe($pdo, (int) $orderOwner, 'offer_received', [
            'offer_id' => $offerId,
            'bd' => $bdInt,
            'ad_id' => $orderId,
            'from_user_id' => $performerId,
        ]);
    } catch (Throwable $e) {
        // ignore push errors
    }

    echo json_encode(['status' => 'success', 'message' => 'Data added successfully']);
}
