<?php
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$idUser = $_POST['idusers'] ?? null;
$bd = $_POST['bd'] ?? null;
$idUserP = $_POST['iduserp'] ?? null;

if (!$idUser || !$bd || !$idUserP) {
    echo json_encode(['isp' => 'Error: Missing parameters'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $conn = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $conn->prepare(
        'SELECT isp FROM offer_dataf
         WHERE iduserp = :idUserP AND iduser = :idUser AND bd = :bd
         LIMIT 1'
    );
    $stmt->bindParam(':idUser', $idUser);
    $stmt->bindParam(':bd', $bd);
    $stmt->bindParam(':idUserP', $idUserP);
    $stmt->execute();

    $result = $stmt->fetchColumn();

    if ($result === false) {
        echo json_encode(['isp' => 'Not found'], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(['isp' => $result], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    echo json_encode(['isp' => 'Database error: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}