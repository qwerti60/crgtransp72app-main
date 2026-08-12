<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/include/api_bootstrap.php';
require_once __DIR__ . '/include/subscription_invoices.php';
require_once __DIR__ . '/token_auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed'], JSON_UNESCAPED_UNICODE);
    exit;
}

$raw = file_get_contents('php://input') ?: '';
$data = json_decode($raw, true);
if (!is_array($data)) {
    $data = $_POST;
}

$token = trim((string) ($data['token'] ?? ''));
$packageId = (int) ($data['package_id'] ?? 0);
$promoCode = trim((string) ($data['promo_code'] ?? ''));

if ($token === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Token required'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $pdo = tp_pdo();
    $userId = resolveUserIdFromToken($pdo, $token);
    if ($userId === null) {
        http_response_code(401);
        echo json_encode(['success' => false, 'error' => 'Unauthorized'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $result = crg_invoice_create_request($pdo, $userId, $packageId, $promoCode);
    if (($result['ok'] ?? false) !== true) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => (string) ($result['error'] ?? 'Ошибка'),
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode([
        'success' => true,
        'invoice_request_id' => (int) ($result['id'] ?? 0),
        'message' => 'Заявка на счёт принята. Менеджер выставит счёт в ближайшее время.',
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Server error'], JSON_UNESCAPED_UNICODE);
}
