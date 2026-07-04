<?php
/**
 * Заказчик: предложение заказа исполнителю (таблица offer_dataf).
 * Те же поля, что add_offer.php, но другая таблица — не смешивать с offer_data (исполнитель / OfferScreen).
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

$customerId = (int) $iduserp;
$adId = (int) $iduser;
$bdInt = (int) $bd;

if ($customerId <= 0 || $adId <= 0 || $bdInt <= 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Invalid parameters'], JSON_UNESCAPED_UNICODE);
    exit;
}

$adOwner = crg_performer_ad_owner_id($pdo, $adId, $bdInt);
if ($adOwner === null) {
    http_response_code(404);
    echo json_encode(['status' => 'error', 'message' => 'Ad not found'], JSON_UNESCAPED_UNICODE);
    exit;
}
if ($adOwner === $customerId) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Cannot offer on your own ad'], JSON_UNESCAPED_UNICODE);
    exit;
}

$sqlExists = 'SELECT COUNT(*)
              FROM offer_dataf
              WHERE iduserp = ? AND iduser = ? AND bd = ?
              LIMIT 1';
$stmt = $pdo->prepare($sqlExists);
$stmt->execute([$iduserp, $iduser, $bd]);
$exists = $stmt->fetchColumn() > 0;

if ($exists) {
    $sqlUpdate = 'UPDATE offer_dataf
                  SET cena = ?, about = ?, isp = 0
                  WHERE iduserp = ? AND iduser = ? AND bd = ?';
    $pdo->prepare($sqlUpdate)->execute([$cena, $about, $iduserp, $iduser, $bd]);

    echo json_encode(['status' => 'updated', 'message' => 'Data updated successfully']);
} else {
    $sqlInsert = 'INSERT INTO offer_dataf (cena, about, iduserp, iduser, bd)
                  VALUES (?, ?, ?, ?, ?)';
    $pdo->prepare($sqlInsert)->execute([$cena, $about, $iduserp, $iduser, $bd]);
    $offerId = (int) $pdo->lastInsertId();
    try {
        require_once __DIR__ . '/include/chat_core.php';
        crg_chat_on_offer_dataf($pdo, $offerId, (int) $iduserp, (int) $iduser, (int) $bd);
    } catch (Throwable $e) {
        // ignore chat hook errors
    }

    echo json_encode(['status' => 'success', 'message' => 'Data added successfully']);
}
