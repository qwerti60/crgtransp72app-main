<?php
/**
 * Удаление заявки заказчика из offer_dataf (см. add_offerzakaz.php / OfferScreen2).
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$input   = json_decode(file_get_contents('php://input'), true) ?: $_POST;
$iduserp = isset($input['iduserp']) ? (string) $input['iduserp'] : '';
$iduser  = isset($input['iduser']) ? (string) $input['iduser'] : '';
$bd      = isset($input['bd']) ? (int) $input['bd'] : 0;

if ($iduserp === '' || $iduser === '' || $bd <= 0) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Некорректные параметры'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $stmt = $pdo->prepare(
        'DELETE FROM offer_dataf WHERE iduserp = ? AND iduser = ? AND bd = ?'
    );
    $stmt->execute([$iduserp, $iduser, $bd]);
    echo json_encode(['ok' => true, 'deleted' => $stmt->rowCount()], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'message' => 'Ошибка базы данных'], JSON_UNESCAPED_UNICODE);
}
