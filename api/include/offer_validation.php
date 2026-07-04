<?php
/**
 * Проверка владельца объявления при создании отклика.
 */
declare(strict_types=1);

function crg_customer_order_owner_id(PDO $pdo, int $orderId, int $bd): ?int
{
    $tables = [1 => 'orders', 2 => 'orderst', 3 => 'ordersg'];
    $table = $tables[$bd] ?? null;
    if ($table === null) {
        return null;
    }

    $stmt = $pdo->prepare("SELECT iduser FROM {$table} WHERE id = ? LIMIT 1");
    $stmt->execute([$orderId]);
    $owner = $stmt->fetchColumn();

    return $owner !== false ? (int) $owner : null;
}

function crg_performer_ad_owner_id(PDO $pdo, int $adId, int $bd): ?int
{
    $tables = [1 => 'add_ob_gp', 2 => 'add_ob_vidt', 3 => 'add_ob_gr'];
    $table = $tables[$bd] ?? null;
    if ($table === null) {
        return null;
    }

    $stmt = $pdo->prepare("SELECT iduser FROM {$table} WHERE id = ? LIMIT 1");
    $stmt->execute([$adId]);
    $owner = $stmt->fetchColumn();

    return $owner !== false ? (int) $owner : null;
}
