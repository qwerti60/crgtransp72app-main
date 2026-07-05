<?php
/**
 * GET: iduser — id исполнителя, truck — id объявления/заказа, bd — площадка.
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';
require_once __DIR__ . '/include/offer_status.php';

$iduser = (int) ($_GET['iduser'] ?? 0);
$truck  = (int) ($_GET['truck'] ?? 0);
$bd     = (int) ($_GET['bd'] ?? 0);

if ($iduser <= 0 || $truck <= 0) {
    echo json_encode([
        'exists' => false,
        'editable' => false,
        'refused' => false,
        'status' => null,
    ]);
    exit;
}

try {
    $conn = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $conn->prepare(
        'SELECT status FROM offer_data
         WHERE iduserp = :iduserp AND iduser = :iduser AND bd = :bd
           AND status IN (:active, :refused)
         ORDER BY id DESC
         LIMIT 1'
    );
    $active = CRG_OFFER_STATUS_ACTIVE;
    $refused = CRG_OFFER_STATUS_REFUSED;
    $stmt->bindValue(':iduserp', $iduser, PDO::PARAM_INT);
    $stmt->bindValue(':iduser', $truck, PDO::PARAM_INT);
    $stmt->bindValue(':bd', $bd, PDO::PARAM_INT);
    $stmt->bindValue(':active', $active, PDO::PARAM_INT);
    $stmt->bindValue(':refused', $refused, PDO::PARAM_INT);
    $stmt->execute();

    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        echo json_encode([
            'exists' => false,
            'editable' => false,
            'refused' => false,
            'status' => null,
        ]);
        exit;
    }

    $status = (int) $row['status'];
    echo json_encode([
        'exists' => true,
        'editable' => $status === CRG_OFFER_STATUS_ACTIVE,
        'refused' => $status === CRG_OFFER_STATUS_REFUSED,
        'status' => $status,
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'exists' => false,
        'editable' => false,
        'refused' => false,
        'status' => null,
    ]);
}
