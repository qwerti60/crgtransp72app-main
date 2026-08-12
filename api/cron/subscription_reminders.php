<?php
declare(strict_types=1);

/**
 * CLI/cron: напоминания об истечении подписки.
 * Пример crontab: 0 9 * * * php /path/to/api/cron/subscription_reminders.php
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    header('Content-Type: text/plain; charset=utf-8');
    echo "CLI only\n";
    exit(1);
}

require_once __DIR__ . '/../databd.php';
require_once __DIR__ . '/../include/deal_push.php';

$pdo = new PDO(
    "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
    $username,
    $password,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$sentEnding = 0;
$sentExpired = 0;
$errors = 0;

try {
    $stEnding = $pdo->query(
        "SELECT u.idusers AS id
         FROM users u
         INNER JOIN subscriptions s ON s.iduser = u.idusers
         WHERE s.date = DATE_ADD(CURDATE(), INTERVAL 3 DAY)"
    );
    foreach ($stEnding->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $uid = (int) ($row['id'] ?? 0);
        $res = crg_push_deal_event($pdo, $uid, 'subscription_ending', [
            'days_left' => 3,
        ]);
        if ($res === true) {
            $sentEnding++;
        } elseif (is_string($res)) {
            $errors++;
        }
    }

    $stExpired = $pdo->query(
        "SELECT u.idusers AS id
         FROM users u
         INNER JOIN subscriptions s ON s.iduser = u.idusers
         WHERE s.date = CURDATE()"
    );
    foreach ($stExpired->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $uid = (int) ($row['id'] ?? 0);
        $res = crg_push_deal_event($pdo, $uid, 'subscription_expired', [
            'days_left' => 0,
        ]);
        if ($res === true) {
            $sentExpired++;
        } elseif (is_string($res)) {
            $errors++;
        }
    }
} catch (Throwable $e) {
    fwrite(STDERR, 'subscription_reminders error: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}

echo json_encode([
    'ok' => true,
    'ending_3d' => $sentEnding,
    'expired_today' => $sentExpired,
    'errors' => $errors,
], JSON_UNESCAPED_UNICODE) . PHP_EOL;
