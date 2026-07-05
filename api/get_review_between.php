<?php
/**
 * Отзыв между исполнителем и заказчиком (для редактирования в форме).
 *
 * GET:
 *   table — reviews (исполнитель→заказчик) | reviewsisp (заказчик→исполнитель)
 *   user_id — id исполнителя (поле user_id в обеих таблицах)
 *   target_user_id — id заказчика (поле target_user_id в обеих таблицах)
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

try {
    $table = isset($_GET['table']) ? trim($_GET['table']) : '';
    $performerId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
    $customerId = isset($_GET['target_user_id']) ? (int) $_GET['target_user_id'] : 0;

    if (!in_array($table, ['reviews', 'reviewsisp'], true) || $performerId <= 0 || $customerId <= 0) {
        echo json_encode(['found' => false], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $sql = $table === 'reviews'
        ? 'SELECT rating, comment, datastamp FROM reviews WHERE user_id = ? AND target_user_id = ? LIMIT 1'
        : 'SELECT rating, comment, datastamp FROM reviewsisp WHERE user_id = ? AND target_user_id = ? LIMIT 1';

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$performerId, $customerId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row === false) {
        echo json_encode(['found' => false], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode([
        'found' => true,
        'rating' => (int) $row['rating'],
        'comment' => (string) $row['comment'],
        'datastamp' => (string) ($row['datastamp'] ?? ''),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['found' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
