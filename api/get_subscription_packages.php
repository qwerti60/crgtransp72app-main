<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/databd.php';
require_once __DIR__ . '/include/subscription_packages.php';

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'DB', 'packages' => []], JSON_UNESCAPED_UNICODE);
    exit;
}

$packages = crg_subscription_packages_active($pdo);
if ($packages === []) {
    // Fallback на legacy config
    try {
        $st = $pdo->query(
            'SELECT days, price_rub FROM subscription_config WHERE is_active = 1 ORDER BY id DESC LIMIT 1'
        );
        $row = $st ? $st->fetch(PDO::FETCH_ASSOC) : false;
        $days = $row ? (int) ($row['days'] ?? 30) : 30;
        $price = $row ? (int) ($row['price_rub'] ?? 300) : 300;
        $packages = [[
            'id' => 0,
            'code' => 'month',
            'title' => 'Месяц',
            'days' => $days > 0 ? $days : 30,
            'price_rub' => $price > 0 ? $price : 300,
            'sort_order' => 10,
        ]];
    } catch (Throwable $e) {
        $packages = [[
            'id' => 0,
            'code' => 'month',
            'title' => 'Месяц',
            'days' => 30,
            'price_rub' => 300,
            'sort_order' => 10,
        ]];
    }
}

$out = [];
foreach ($packages as $p) {
    $out[] = [
        'id' => (int) ($p['id'] ?? 0),
        'code' => (string) ($p['code'] ?? ''),
        'title' => (string) ($p['title'] ?? ''),
        'days' => (int) ($p['days'] ?? 0),
        'price_rub' => (int) ($p['price_rub'] ?? 0),
        'amount_kopecks' => ((int) ($p['price_rub'] ?? 0)) * 100,
        'sort_order' => (int) ($p['sort_order'] ?? 0),
    ];
}

echo json_encode(['success' => true, 'packages' => $out], JSON_UNESCAPED_UNICODE);
