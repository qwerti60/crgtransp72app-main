<?php
/**
 * Очистка дублей отзывов и подготовка уникальных индексов.
 * Запуск: php scripts/dedupe_reviews.php
 */
require_once __DIR__ . '/../api/databd.php';

$pdo = new PDO(
    "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
    $username,
    $password,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$deletedSelf = $pdo->exec('DELETE FROM reviewsisp WHERE user_id = target_user_id');
echo "Удалено некорректных reviewsisp (user_id = target_user_id): {$deletedSelf}\n";

foreach (['reviewsisp', 'reviews'] as $table) {
    $pdo->exec(
        "DELETE r1 FROM {$table} r1
         INNER JOIN {$table} r2
           ON r1.user_id = r2.user_id
          AND r1.target_user_id = r2.target_user_id
          AND r1.id < r2.id"
    );
    echo "Дубли в {$table} удалены (оставлен последний id).\n";
}

foreach (
    [
        'reviewsisp' => 'uq_reviewsisp_performer_customer',
        'reviews' => 'uq_reviews_performer_customer',
    ] as $table => $indexName
) {
    $st = $pdo->query("SHOW INDEX FROM {$table} WHERE Key_name = " . $pdo->quote($indexName));
    if ($st->fetch() === false) {
        $pdo->exec(
            "ALTER TABLE {$table} ADD UNIQUE KEY {$indexName} (user_id, target_user_id)"
        );
        echo "Добавлен UNIQUE на {$table}.\n";
    } else {
        echo "UNIQUE на {$table} уже есть.\n";
    }
}

echo "Готово.\n";
