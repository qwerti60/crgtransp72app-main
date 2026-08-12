<?php
declare(strict_types=1);

function crg_subscription_packages_table_exists(PDO $pdo): bool
{
    try {
        $pdo->query('SELECT 1 FROM subscription_packages LIMIT 1');
        return true;
    } catch (Throwable $e) {
        return false;
    }
}

function crg_promo_codes_table_exists(PDO $pdo): bool
{
    try {
        $pdo->query('SELECT 1 FROM promo_codes LIMIT 1');
        return true;
    } catch (Throwable $e) {
        return false;
    }
}

/**
 * @return list<array<string, mixed>>
 */
function crg_subscription_packages_active(PDO $pdo): array
{
    if (!crg_subscription_packages_table_exists($pdo)) {
        return [];
    }
    $st = $pdo->query(
        'SELECT id, code, title, days, price_rub, sort_order
         FROM subscription_packages
         WHERE is_active = 1
         ORDER BY sort_order ASC, id ASC'
    );

    return $st ? $st->fetchAll(PDO::FETCH_ASSOC) : [];
}

/**
 * @return array<string, mixed>|null
 */
function crg_subscription_package_by_id(PDO $pdo, int $id): ?array
{
    if ($id <= 0 || !crg_subscription_packages_table_exists($pdo)) {
        return null;
    }
    $st = $pdo->prepare(
        'SELECT id, code, title, days, price_rub, sort_order, is_active
         FROM subscription_packages WHERE id = ? LIMIT 1'
    );
    $st->execute([$id]);
    $row = $st->fetch(PDO::FETCH_ASSOC);

    return $row !== false ? $row : null;
}

/**
 * @return array{ok: bool, error?: string, promo?: array<string, mixed>, discount_rub?: int, amount_rub?: int}
 */
function crg_promo_validate(PDO $pdo, string $code, int $packagePriceRub, int $userId = 0): array
{
    $code = strtoupper(trim($code));
    if ($code === '') {
        return ['ok' => false, 'error' => 'Введите промокод'];
    }
    if (!crg_promo_codes_table_exists($pdo)) {
        return ['ok' => false, 'error' => 'Промокоды недоступны'];
    }

    $st = $pdo->prepare(
        'SELECT * FROM promo_codes WHERE UPPER(code) = ? LIMIT 1'
    );
    $st->execute([$code]);
    $promo = $st->fetch(PDO::FETCH_ASSOC);
    if ($promo === false) {
        return ['ok' => false, 'error' => 'Промокод не найден'];
    }
    if ((int) ($promo['is_active'] ?? 0) !== 1) {
        return ['ok' => false, 'error' => 'Промокод неактивен'];
    }
    $validUntil = (string) ($promo['valid_until'] ?? '');
    if ($validUntil !== '' && $validUntil < date('Y-m-d')) {
        return ['ok' => false, 'error' => 'Срок действия промокода истёк'];
    }
    $maxUses = $promo['max_uses'] !== null ? (int) $promo['max_uses'] : null;
    $used = (int) ($promo['used_count'] ?? 0);
    if ($maxUses !== null && $used >= $maxUses) {
        return ['ok' => false, 'error' => 'Лимит использований промокода исчерпан'];
    }

    $type = (string) ($promo['discount_type'] ?? 'percent');
    $value = (int) ($promo['discount_value'] ?? 0);
    $discount = 0;
    if ($type === 'fixed') {
        $discount = max(0, min($packagePriceRub, $value));
    } else {
        $pct = max(0, min(100, $value));
        $discount = (int) floor($packagePriceRub * $pct / 100);
    }
    $amount = max(0, $packagePriceRub - $discount);

    return [
        'ok' => true,
        'promo' => $promo,
        'discount_rub' => $discount,
        'amount_rub' => $amount,
    ];
}

function crg_promo_redeem(
    PDO $pdo,
    int $promoId,
    int $userId,
    ?int $packageId,
    string $orderId
): void {
    if ($promoId <= 0 || $userId <= 0) {
        return;
    }
    try {
        $pdo->prepare(
            'INSERT INTO promo_redemptions (promo_id, user_id, package_id, order_id, created_at)
             VALUES (?, ?, ?, ?, NOW())'
        )->execute([$promoId, $userId, $packageId, $orderId !== '' ? $orderId : null]);
        $pdo->prepare(
            'UPDATE promo_codes SET used_count = used_count + 1 WHERE id = ?'
        )->execute([$promoId]);
    } catch (Throwable $e) {
        // ignore
    }
}

/**
 * Синхронизировать default пакет «month» в subscription_config для старых клиентов.
 */
function crg_subscription_sync_legacy_config(PDO $pdo, int $days, int $priceRub): void
{
    try {
        $st = $pdo->query(
            'SELECT id FROM subscription_config WHERE is_active = 1 ORDER BY id DESC LIMIT 1'
        );
        $id = $st ? (int) $st->fetchColumn() : 0;
        if ($id > 0) {
            $pdo->prepare(
                'UPDATE subscription_config SET days = ?, price_rub = ? WHERE id = ?'
            )->execute([$days, $priceRub, $id]);
        } else {
            $pdo->prepare(
                'INSERT INTO subscription_config (days, price_rub, is_active) VALUES (?, ?, 1)'
            )->execute([$days, $priceRub]);
        }
    } catch (Throwable $e) {
        // ignore
    }
}
