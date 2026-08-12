<?php
declare(strict_types=1);

require_once __DIR__ . '/subscription_packages.php';
require_once __DIR__ . '/performer_finances.php';

function crg_invoice_table_exists(PDO $pdo): bool
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $pdo->query('SELECT 1 FROM subscription_invoice_requests LIMIT 1');

        return $exists = true;
    } catch (Throwable $e) {
        return $exists = false;
    }
}

/**
 * Продление подписки (общая логика для карты и счёта).
 *
 * @return array{ok: bool, error?: string, date?: string, order_id?: string}
 */
function crg_subscription_extend_user(
    PDO $pdo,
    int $userId,
    string $orderId,
    int $days,
    int $amountRub,
    ?int $packageId = null,
    ?string $promoCode = null,
    int $discountRub = 0,
    ?int $promoId = null,
    string $paymentMethod = 'card'
): array {
    if ($userId <= 0 || $orderId === '' || $days <= 0) {
        return ['ok' => false, 'error' => 'Некорректные параметры'];
    }

    $st = $pdo->prepare(
        'SELECT id, date FROM subscriptions WHERE iduser = ? ORDER BY id DESC LIMIT 1'
    );
    $st->execute([$userId]);
    $existing = $st->fetch(PDO::FETCH_ASSOC);

    $baseDate = new DateTime('now');
    if ($existing && !empty($existing['date'])) {
        $existingDate = DateTime::createFromFormat('Y-m-d', (string) $existing['date']);
        if ($existingDate instanceof DateTime) {
            $today = new DateTime('today');
            $baseDate = $existingDate > $today ? clone $existingDate : new DateTime('now');
        }
    }
    $newDate = (clone $baseDate)->modify('+' . $days . ' days')->format('Y-m-d');

    if ($existing && isset($existing['id'])) {
        $pdo->prepare(
            'UPDATE subscriptions SET date = ?, payment = ?, count = COALESCE(count, 0) + 1 WHERE id = ?'
        )->execute([$newDate, $orderId, (int) $existing['id']]);
    } else {
        $pdo->prepare(
            'INSERT INTO subscriptions (iduser, date, payment, count) VALUES (?, ?, ?, 1)'
        )->execute([$userId, $newDate, $orderId]);
    }

    crg_finances_log_subscription_payment(
        $pdo,
        $userId,
        $orderId,
        $amountRub,
        $days,
        $newDate,
        $packageId !== null && $packageId > 0 ? $packageId : null,
        $promoCode,
        $discountRub,
        $paymentMethod
    );

    if ($promoId !== null && $promoId > 0) {
        crg_promo_redeem($pdo, $promoId, $userId, $packageId !== null && $packageId > 0 ? $packageId : null, $orderId);
    }

    return ['ok' => true, 'date' => $newDate, 'order_id' => $orderId];
}

/**
 * @return array{ok: bool, error?: string, id?: int}
 */
function crg_invoice_create_request(
    PDO $pdo,
    int $userId,
    int $packageId,
    string $promoCode = ''
): array {
    if (!crg_invoice_table_exists($pdo)) {
        return ['ok' => false, 'error' => 'Счета недоступны: выполните migrate_p3_features.sql'];
    }
    if ($userId <= 0) {
        return ['ok' => false, 'error' => 'Некорректный пользователь'];
    }

    $st = $pdo->prepare(
        'SELECT statNum, namefirm, innStr, kppStr, ogrnStr FROM users WHERE idusers = ? LIMIT 1'
    );
    $st->execute([$userId]);
    $user = $st->fetch(PDO::FETCH_ASSOC);
    if ($user === false) {
        return ['ok' => false, 'error' => 'Пользователь не найден'];
    }
    if ((int) ($user['statNum'] ?? 0) !== 1) {
        return ['ok' => false, 'error' => 'Счёт доступен только для юридических лиц'];
    }

    $pending = $pdo->prepare(
        "SELECT id FROM subscription_invoice_requests
         WHERE user_id = ? AND status IN ('requested','issued') LIMIT 1"
    );
    $pending->execute([$userId]);
    if ($pending->fetch()) {
        return ['ok' => false, 'error' => 'У вас уже есть активная заявка на счёт'];
    }

    $days = 30;
    $amountRub = 0;
    $discountRub = 0;
    $promoId = 0;
    $promoCode = strtoupper(trim($promoCode));

    if ($packageId > 0) {
        $pkg = crg_subscription_package_by_id($pdo, $packageId);
        if ($pkg === null || (int) ($pkg['is_active'] ?? 0) !== 1) {
            return ['ok' => false, 'error' => 'Пакет не найден'];
        }
        $days = max(1, (int) ($pkg['days'] ?? 30));
        $basePrice = (int) ($pkg['price_rub'] ?? 0);
        $amountRub = $basePrice;
        if ($promoCode !== '') {
            $promoRes = crg_promo_validate($pdo, $promoCode, $basePrice, $userId);
            if (($promoRes['ok'] ?? false) === true) {
                $discountRub = (int) ($promoRes['discount_rub'] ?? 0);
                $amountRub = (int) ($promoRes['amount_rub'] ?? $basePrice);
                $promoId = (int) (($promoRes['promo']['id'] ?? 0));
            }
        }
    }

    if ($amountRub <= 0) {
        return ['ok' => false, 'error' => 'Не удалось определить сумму'];
    }

    $pdo->prepare(
        'INSERT INTO subscription_invoice_requests
         (user_id, package_id, days, amount_rub, discount_rub, promo_code, company_name, inn, kpp, ogrn, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, \'requested\')'
    )->execute([
        $userId,
        $packageId > 0 ? $packageId : null,
        $days,
        $amountRub,
        $discountRub,
        $promoCode !== '' ? $promoCode : null,
        trim((string) ($user['namefirm'] ?? '')),
        trim((string) ($user['innStr'] ?? '')),
        trim((string) ($user['kppStr'] ?? '')) ?: null,
        trim((string) ($user['ogrnStr'] ?? '')) ?: null,
    ]);

    return ['ok' => true, 'id' => (int) $pdo->lastInsertId()];
}

/**
 * @return list<array<string, mixed>>
 */
function crg_invoice_list_admin(PDO $pdo, ?string $status = null, int $limit = 200): array
{
    if (!crg_invoice_table_exists($pdo)) {
        return [];
    }
    $sql = 'SELECT i.*, u.email, u.phone, u.firstName, u.lastName
            FROM subscription_invoice_requests i
            LEFT JOIN users u ON u.idusers = i.user_id';
    $params = [];
    if ($status !== null && $status !== '') {
        $sql .= ' WHERE i.status = ?';
        $params[] = $status;
    }
    $sql .= ' ORDER BY i.created_at DESC LIMIT ' . max(1, min(500, $limit));
    $st = $pdo->prepare($sql);
    $st->execute($params);

    return $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

/**
 * @return list<array<string, mixed>>
 */
function crg_invoice_list_user(PDO $pdo, int $userId, int $limit = 20): array
{
    if (!crg_invoice_table_exists($pdo) || $userId <= 0) {
        return [];
    }
    $st = $pdo->prepare(
        'SELECT id, package_id, days, amount_rub, discount_rub, promo_code, status,
                invoice_number, issued_at, paid_at, created_at
         FROM subscription_invoice_requests
         WHERE user_id = ?
         ORDER BY created_at DESC
         LIMIT ' . max(1, min(50, $limit))
    );
    $st->execute([$userId]);

    return $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

/** @return array{ok: bool, error?: string} */
function crg_invoice_mark_issued(PDO $pdo, int $id, string $invoiceNumber, string $adminNote = ''): array
{
    if (!crg_invoice_table_exists($pdo) || $id <= 0) {
        return ['ok' => false, 'error' => 'Заявка не найдена'];
    }
    $invoiceNumber = trim($invoiceNumber);
    if ($invoiceNumber === '') {
        return ['ok' => false, 'error' => 'Укажите номер счёта'];
    }
    $st = $pdo->prepare('SELECT * FROM subscription_invoice_requests WHERE id = ? LIMIT 1');
    $st->execute([$id]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return ['ok' => false, 'error' => 'Заявка не найдена'];
    }
    if ((string) ($row['status'] ?? '') !== 'requested') {
        return ['ok' => false, 'error' => 'Статус заявки не позволяет выставить счёт'];
    }
    $pdo->prepare(
        "UPDATE subscription_invoice_requests
         SET status = 'issued', invoice_number = ?, admin_note = ?, issued_at = NOW()
         WHERE id = ?"
    )->execute([$invoiceNumber, $adminNote !== '' ? $adminNote : null, $id]);

    return ['ok' => true];
}

/** @return array{ok: bool, error?: string, date?: string} */
function crg_invoice_mark_paid(PDO $pdo, int $id, string $adminNote = ''): array
{
    if (!crg_invoice_table_exists($pdo) || $id <= 0) {
        return ['ok' => false, 'error' => 'Заявка не найдена'];
    }
    $st = $pdo->prepare('SELECT * FROM subscription_invoice_requests WHERE id = ? LIMIT 1');
    $st->execute([$id]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return ['ok' => false, 'error' => 'Заявка не найдена'];
    }
    $status = (string) ($row['status'] ?? '');
    if ($status !== 'issued' && $status !== 'requested') {
        return ['ok' => false, 'error' => 'Оплата возможна только для выставленного счёта'];
    }

    $userId = (int) ($row['user_id'] ?? 0);
    $days = max(1, (int) ($row['days'] ?? 30));
    $amountRub = (int) ($row['amount_rub'] ?? 0);
    $packageId = (int) ($row['package_id'] ?? 0);
    $promoCode = trim((string) ($row['promo_code'] ?? ''));
    $discountRub = (int) ($row['discount_rub'] ?? 0);
    $orderId = 'INV-' . $id . '-' . date('YmdHis');

    $extend = crg_subscription_extend_user(
        $pdo,
        $userId,
        $orderId,
        $days,
        $amountRub,
        $packageId > 0 ? $packageId : null,
        $promoCode !== '' ? $promoCode : null,
        $discountRub,
        null,
        'invoice'
    );
    if (($extend['ok'] ?? false) !== true) {
        return ['ok' => false, 'error' => (string) ($extend['error'] ?? 'Не удалось продлить подписку')];
    }

    $pdo->prepare(
        "UPDATE subscription_invoice_requests
         SET status = 'paid', paid_at = NOW(), payment_order_id = ?,
             admin_note = CONCAT(COALESCE(admin_note, ''), ?)
         WHERE id = ?"
    )->execute([
        $orderId,
        $adminNote !== '' ? "\n" . $adminNote : '',
        $id,
    ]);

    return ['ok' => true, 'date' => (string) ($extend['date'] ?? '')];
}

/** @return array{ok: bool, error?: string} */
function crg_invoice_cancel(PDO $pdo, int $id): array
{
    if (!crg_invoice_table_exists($pdo) || $id <= 0) {
        return ['ok' => false, 'error' => 'Заявка не найдена'];
    }
    $pdo->prepare(
        "UPDATE subscription_invoice_requests SET status = 'cancelled' WHERE id = ? AND status IN ('requested','issued')"
    )->execute([$id]);

    return ['ok' => true];
}

function crg_invoice_status_label(string $status): string
{
    return match ($status) {
        'requested' => 'Запрошен',
        'issued' => 'Счёт выставлен',
        'paid' => 'Оплачен',
        'cancelled' => 'Отменён',
        default => $status,
    };
}

function crg_invoice_pending_count(PDO $pdo): int
{
    if (!crg_invoice_table_exists($pdo)) {
        return 0;
    }
    try {
        return (int) $pdo->query(
            "SELECT COUNT(*) FROM subscription_invoice_requests WHERE status IN ('requested','issued')"
        )->fetchColumn();
    } catch (Throwable $e) {
        return 0;
    }
}
