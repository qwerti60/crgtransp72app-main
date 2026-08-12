<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/databd.php';
require_once __DIR__ . '/token_auth.php';

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $token = isset($_GET['token']) ? (string) $_GET['token'] : '';
    $userId = resolveUserIdFromToken($pdo, $token);
    if ($userId === null) {
        http_response_code(401);
        echo json_encode(['success' => false, 'error' => 'Unauthorized'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $limit = min(30, max(1, (int) ($_GET['limit'] ?? 20)));
    $items = [];

    $queries = [
        [
            'bd' => 1,
            'table' => 'orders',
            'title' => "CONCAT(COALESCE(maxgruz,''), ' · ', COALESCE(city,''))",
        ],
        [
            'bd' => 2,
            'table' => 'orderst',
            'title' => "CONCAT(COALESCE(vidt,''), ' · ', COALESCE(city,''))",
        ],
        [
            'bd' => 3,
            'table' => 'ordersg',
            'title' => "CONCAT('Грузчики · ', COALESCE(city,''))",
        ],
    ];

    foreach ($queries as $q) {
        $table = $q['table'];
        $chk = $pdo->query("SHOW TABLES LIKE " . $pdo->quote($table));
        if ($chk->fetch() === false) {
            continue;
        }
        $sql = "SELECT id, {$q['title']} AS title, city, created_at
                FROM `{$table}`
                WHERE iduser = ?
                ORDER BY id DESC
                LIMIT {$limit}";
        $st = $pdo->prepare($sql);
        $st->execute([(string) $userId]);
        foreach ($st->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $items[] = [
                'bd' => (int) $q['bd'],
                'id' => (int) ($row['id'] ?? 0),
                'title' => trim((string) ($row['title'] ?? '')),
                'city' => (string) ($row['city'] ?? ''),
                'created_at' => (string) ($row['created_at'] ?? ''),
            ];
        }
    }

    usort($items, static function (array $a, array $b): int {
        return strcmp((string) ($b['created_at'] ?? ''), (string) ($a['created_at'] ?? ''));
    });
    $items = array_slice($items, 0, $limit);

    echo json_encode(['success' => true, 'templates' => $items], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
