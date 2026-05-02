<?php
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$rawBody = file_get_contents('php://input');
$data = json_decode($rawBody, true);
if (!is_array($data)) {
    $data = $_POST;
}

$iduserp = isset($data['iduserp']) ? (int)$data['iduserp'] : 0;
$iduser = isset($data['iduser']) ? (int)$data['iduser'] : 0;
$bd = isset($data['bd']) ? (int)$data['bd'] : 0;

if ($iduserp <= 0 || $iduser <= 0 || $bd <= 0) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid params',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );

    $sql = 'DELETE FROM offer_data
            WHERE iduserp = :iduserp
              AND iduser = :iduser
              AND bd = :bd
              AND status = 0';

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':iduserp' => $iduserp,
        ':iduser' => $iduser,
        ':bd' => $bd,
    ]);

    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Record deleted successfully',
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'status' => 'not_found',
            'message' => 'No record found to delete',
        ], JSON_UNESCAPED_UNICODE);
    }
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Error deleting data',
    ], JSON_UNESCAPED_UNICODE);
}

