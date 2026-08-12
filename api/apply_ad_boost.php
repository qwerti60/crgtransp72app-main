<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/load_databd.php';
require_once __DIR__ . '/token_auth.php';
require_once __DIR__ . '/include/ad_boost.php';

$userId = 0;
if (!empty($_POST['token'])) {
    try {
        $pdo = new PDO(
            "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
            $username,
            $password,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
        $resolved = resolveUserIdFromToken($pdo, (string) $_POST['token']);
        if ($resolved !== null) {
            $userId = (int) $resolved;
        }
    } catch (Throwable $e) {
        // fall through
    }
}
if ($userId <= 0 && isset($_POST['userId'])) {
    $userId = (int) $_POST['userId'];
}

$bd = (int) ($_POST['bd'] ?? 0);
$adId = (int) ($_POST['adId'] ?? 0);
$tariffId = (int) ($_POST['tariffId'] ?? 0);
$orderId = trim((string) ($_POST['orderId'] ?? ''));

if ($userId <= 0 || $bd <= 0 || $adId <= 0 || $tariffId <= 0 || $orderId === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Некорректные параметры'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $res = crg_boost_apply_payment($pdo, [
        'user_id' => $userId,
        'bd' => $bd,
        'ad_id' => $adId,
        'tariff_id' => $tariffId,
        'payment_order_id' => $orderId,
    ]);
    if (($res['ok'] ?? false) !== true) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => $res['error'] ?? 'Ошибка'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    echo json_encode([
        'success' => true,
        'boosted_until' => $res['boosted_until'] ?? null,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
