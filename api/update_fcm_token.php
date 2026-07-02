<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';
require_once __DIR__ . '/token_auth.php';

$response = ['success' => false];

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $authToken = trim((string) ($_POST['token'] ?? $_GET['token'] ?? ''));
    $fcmToken = trim((string) ($_POST['fcm_token'] ?? ''));

    if ($authToken === '') {
        $response['message'] = 'Требуется токен авторизации';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($fcmToken === '') {
        $response['message'] = 'Требуется FCM-токен';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    require_once __DIR__ . '/include/fcm_push.php';
    $tokenCheck = crg_fcm_validate_device_token($fcmToken);
    if ($tokenCheck !== true) {
        $response['message'] = $tokenCheck;
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    $userId = resolveUserIdFromToken($pdo, $authToken);
    if ($userId === null || $userId <= 0) {
        $response['message'] = 'Пользователь не найден';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    $col = $pdo->query("SHOW COLUMNS FROM users LIKE 'fcm_token'");
    if ($col === false || $col->fetch() === false) {
        $response['message'] = 'Поле fcm_token недоступно в БД';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    $st = $pdo->prepare('UPDATE users SET fcm_token = ? WHERE idusers = ?');
    $st->execute([$fcmToken, $userId]);

    $response['success'] = true;
    $response['user_id'] = $userId;
} catch (Throwable $e) {
    $response['message'] = 'Ошибка сервера';
}

echo json_encode($response, JSON_UNESCAPED_UNICODE);
