<?php
/**
 * GET: iduser — id исполнителя, truck — id объявления/заказа, bd — площадка.
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$iduser = (int) ($_GET['iduser'] ?? 0);
$truck  = (int) ($_GET['truck'] ?? 0);
$bd     = (int) ($_GET['bd'] ?? 0);

if ($iduser <= 0 || $truck <= 0) {
    echo json_encode(['exists' => false]);
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
        'SELECT COUNT(*) FROM offer_data
         WHERE iduserp = :iduserp AND iduser = :iduser AND bd = :bd AND status = 0
         LIMIT 1'
    );
    $stmt->bindParam(':iduserp', $iduser, PDO::PARAM_INT);
    $stmt->bindParam(':iduser', $truck, PDO::PARAM_INT);
    $stmt->bindParam(':bd', $bd, PDO::PARAM_INT);
    $stmt->execute();

    $count = $stmt->fetchColumn();

    echo json_encode(['exists' => ((int) $count > 0)]);
} catch (PDOException $e) {
    echo json_encode(['exists' => false]);
}
