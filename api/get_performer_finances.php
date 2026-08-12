<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if (!isset($_GET['token']) || trim((string) $_GET['token']) === '') {
        echo json_encode(['success' => false, 'error' => 'Token is required'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    require_once __DIR__ . '/token_auth.php';
    require_once __DIR__ . '/include/performer_finances.php';

    $token = (string) $_GET['token'];
    $userId = resolveUserIdFromToken($pdo, $token);
    if ($userId === null || $userId <= 0) {
        echo json_encode(['success' => false, 'error' => 'User not found'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $period = isset($_GET['period']) ? trim((string) $_GET['period']) : 'month';
    $dateFrom = isset($_GET['from']) ? trim((string) $_GET['from']) : null;
    $dateTo = isset($_GET['to']) ? trim((string) $_GET['to']) : null;

    $report = crg_finances_build_report($pdo, $userId, $period, $dateFrom, $dateTo);

    echo json_encode(array_merge(['success' => true], $report), JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Ошибка сервера',
    ], JSON_UNESCAPED_UNICODE);
}
