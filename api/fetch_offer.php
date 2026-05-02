<?php
/**
 * POST: iduserp — исполнитель, userId — id объявления, bd — площадка (как add_offer.php).
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$iduserp = isset($_POST['iduserp']) ? (int) $_POST['iduserp'] : 0;
$userId  = isset($_POST['userId']) ? (int) $_POST['userId'] : 0;
$bd      = isset($_POST['bd']) ? (int) $_POST['bd'] : 0;

if ($iduserp <= 0 || $userId <= 0) {
    http_response_code(400);
    echo json_encode(['message' => 'Некорректные параметры'], JSON_UNESCAPED_UNICODE);
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
        'SELECT cena, about FROM offer_data
         WHERE iduserp = :iduserp AND iduser = :userId AND bd = :bd AND status = 0
         LIMIT 1'
    );
    $stmt->execute([
        ':iduserp' => $iduserp,
        ':userId'  => $userId,
        ':bd'      => $bd,
    ]);

    if ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode([
            'cena' => $row['cena'],
            'about' => $row['about'],
        ], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(404);
        echo json_encode(['message' => 'Запись не найдена'], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка подключения к базе данных'], JSON_UNESCAPED_UNICODE);
}
