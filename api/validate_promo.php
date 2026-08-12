<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/databd.php';
require_once __DIR__ . '/include/subscription_packages.php';

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    $input = $_POST;
}

$code = trim((string) ($input['code'] ?? ''));
$packageId = (int) ($input['package_id'] ?? 0);
$userId = (int) ($input['userId'] ?? $input['user_id'] ?? 0);

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'DB'], JSON_UNESCAPED_UNICODE);
    exit;
}

$price = 0;
$days = 30;
if ($packageId > 0) {
    $pkg = crg_subscription_package_by_id($pdo, $packageId);
    if ($pkg === null || (int) ($pkg['is_active'] ?? 0) !== 1) {
        echo json_encode(['success' => false, 'error' => 'Пакет не найден'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $price = (int) ($pkg['price_rub'] ?? 0);
    $days = (int) ($pkg['days'] ?? 30);
} else {
    $active = crg_subscription_packages_active($pdo);
    if ($active !== []) {
        $price = (int) ($active[0]['price_rub'] ?? 300);
        $days = (int) ($active[0]['days'] ?? 30);
        $packageId = (int) ($active[0]['id'] ?? 0);
    } else {
        $price = 300;
    }
}

$result = crg_promo_validate($pdo, $code, $price, $userId);
if (($result['ok'] ?? false) !== true) {
    echo json_encode([
        'success' => false,
        'error' => (string) ($result['error'] ?? 'Неверный промокод'),
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

echo json_encode([
    'success' => true,
    'package_id' => $packageId,
    'days' => $days,
    'price_rub' => $price,
    'discount_rub' => (int) ($result['discount_rub'] ?? 0),
    'amount_rub' => (int) ($result['amount_rub'] ?? $price),
    'amount_kopecks' => ((int) ($result['amount_rub'] ?? $price)) * 100,
    'promo_code' => strtoupper(trim($code)),
], JSON_UNESCAPED_UNICODE);
