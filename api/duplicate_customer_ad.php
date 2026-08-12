<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/databd.php';
require_once __DIR__ . '/token_auth.php';

/**
 * @return array{table: string, user_col: string}|null
 */
function crg_customer_ad_table(int $bd): ?array
{
    switch ($bd) {
        case 1:
            return ['table' => 'orders', 'user_col' => 'iduser'];
        case 2:
            return ['table' => 'orderst', 'user_col' => 'iduser'];
        case 3:
            return ['table' => 'ordersg', 'user_col' => 'iduser'];
        default:
            return null;
    }
}

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $token = isset($_POST['token']) ? (string) $_POST['token'] : '';
    $userId = resolveUserIdFromToken($pdo, $token);
    if ($userId === null) {
        http_response_code(401);
        echo json_encode(['success' => false, 'error' => 'Unauthorized'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $bd = (int) ($_POST['bd'] ?? 0);
    $sourceId = (int) ($_POST['source_id'] ?? 0);
    $cfg = crg_customer_ad_table($bd);
    if ($cfg === null || $sourceId <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Некорректные параметры'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $table = $cfg['table'];
    $userCol = $cfg['user_col'];
    $st = $pdo->prepare("SELECT * FROM `{$table}` WHERE id = ? AND {$userCol} = ? LIMIT 1");
    $st->execute([$sourceId, (string) $userId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Объявление не найдено'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    unset($row['id']);
    $today = date('Y-m-d');
    $plus30 = date('Y-m-d', strtotime('+30 days'));
    if (array_key_exists('startdate', $row)) {
        $row['startdate'] = $today;
    }
    if (array_key_exists('enddate', $row)) {
        $row['enddate'] = $plus30;
    }
    if (array_key_exists('enddatez', $row)) {
        $row['enddatez'] = $plus30;
    }
    if (array_key_exists('created_at', $row)) {
        unset($row['created_at']);
    }

    $cols = array_keys($row);
    $placeholders = array_fill(0, count($cols), '?');
    $values = array_values($row);
    $values[] = (string) $userId;
    $cols[] = $userCol;

    $sql = 'INSERT INTO `' . $table . '` (`' . implode('`,`', $cols) . '`) VALUES (' . implode(',', $placeholders) . ')';
    $ins = $pdo->prepare($sql);
    $ins->execute($values);
    $newId = (int) $pdo->lastInsertId();

    echo json_encode([
        'success' => true,
        'bd' => $bd,
        'new_id' => $newId,
        'message' => 'Заявка создана по шаблону',
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
