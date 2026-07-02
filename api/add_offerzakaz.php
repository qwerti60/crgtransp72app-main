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

    echo json_encode(['status' => 'success', 'message' => 'Data added successfully']);
}
