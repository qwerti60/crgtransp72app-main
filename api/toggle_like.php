<?php
header('Content-Type: application/json; charset=utf-8');

$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db   = "u2395188_apps";

try {
    $conn = new PDO(
        "mysql:host=$host;dbname=$db;charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $idusers = (int)($_GET['idusers'] ?? 0);
    $id      = (int)($_GET['id'] ?? 0);
    $usersid = (int)($_GET['usersid'] ?? 0);
    $bd      = (string)($_GET['bd'] ?? '');

    if ($idusers <= 0 || $id <= 0 || $usersid <= 0) {
        echo json_encode(['success' => false, 'error' => 'bad_params']);
        exit;
    }

    $check = $conn->prepare("
        SELECT 1
        FROM likes
        WHERE idusers = :idusers AND id = :id AND usersid = :usersid
        LIMIT 1
    ");
    $check->execute([
        'idusers' => $idusers,
        'id' => $id,
        'usersid' => $usersid
    ]);

    if ($check->fetchColumn()) {
        $del = $conn->prepare("
            DELETE FROM likes
            WHERE idusers = :idusers AND id = :id AND usersid = :usersid
        ");
        $del->execute([
            'idusers' => $idusers,
            'id' => $id,
            'usersid' => $usersid
        ]);

        echo json_encode(['success' => false]);
    } else {
        $ins = $conn->prepare("
            INSERT INTO likes (idusers, id, bd, usersid)
            VALUES (:idusers, :id, :bd, :usersid)
        ");
        $ins->execute([
            'idusers' => $idusers,
            'id' => $id,
            'bd' => $bd,
            'usersid' => $usersid
        ]);

        echo json_encode(['success' => true]);
    }
} catch (Throwable $e) {
    echo json_encode(['success' => false, 'error' => 'server_error']);
}
