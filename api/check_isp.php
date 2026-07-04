<?php
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$idUser = $_POST['idusers'] ?? null;
$bd = $_POST['bd'] ?? null;
$idUserP = $_POST['iduserp'] ?? null;
$source = isset($_POST['source']) && $_POST['source'] === 'customer_order'
    ? 'customer_order'
    : 'performer_ad';

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

    if ($source === 'customer_order') {
        $stmt = $conn->prepare(
            'SELECT isp FROM offer_data
             WHERE iduser = :idUser AND iduserp = :idUserP AND bd = :bd
               AND (status = 0 OR status IS NULL)
             LIMIT 1'
        );
    } else {
        $stmt = $conn->prepare(
            'SELECT isp FROM offer_dataf
             WHERE iduserp = :idUserP AND iduser = :idUser AND bd = :bd
             LIMIT 1'
        );
    }

    $stmt->bindParam(':idUser', $idUser);
    $stmt->bindParam(':bd', $bd);
    $stmt->bindParam(':idUserP', $idUserP);
    $stmt->execute();

    $result = $stmt->fetchColumn();

    if ($result === false) {
        echo json_encode(['isp' => 0], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(['isp' => (int) $result], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    echo json_encode(['isp' => 'Database error: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
