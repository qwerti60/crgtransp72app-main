<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/include/api_bootstrap.php';
require_once __DIR__ . '/include/subscription_invoices.php';
require_once __DIR__ . '/token_auth.php';

$token = trim((string) ($_GET['token'] ?? ''));
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

    $rows = crg_invoice_list_user($pdo, $userId);
    $active = null;
    foreach ($rows as $r) {
        $st = (string) ($r['status'] ?? '');
        if ($st === 'requested' || $st === 'issued') {
            $active = $r;
            break;
        }
    }

    echo json_encode([
        'success' => true,
        'invoices' => $rows,
        'active' => $active,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Server error'], JSON_UNESCAPED_UNICODE);
}
