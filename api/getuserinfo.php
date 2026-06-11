<?php
header("Content-Type: application/json");

ini_set('default_charset', 'UTF-8');
mb_internal_encoding("UTF-8");

$host = "localhost";
$username = "u2395188_apps72";
$password = "kR3iV2aA6gjU8nC9";
$dbname = "u2395188_apps";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if (!isset($_GET['token']) || $_GET['token'] === '') {
        echo json_encode(['error' => 'Token is required']);
        exit;
    }

    require_once __DIR__ . '/token_auth.php';

    $token = $_GET['token'];
    $userId = resolveUserIdFromToken($pdo, $token);

    if ($userId === null) {
        echo json_encode(['error' => 'User not found']);
        exit;
    }

    $stmt = $pdo->prepare("SELECT idusers, fotouser, firstName, lastName, middleName, city, phone, email FROM users WHERE idusers = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        if ($user['fotouser']) {
            // Преобразуем фотографию пользователя в Base64
            $user['fotouser'] = base64_encode($user['fotouser']);
        }
        echo json_encode($user); // Возвращаем данные пользователя
    } else {
        echo json_encode(['error' => 'User not found']);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}

?>