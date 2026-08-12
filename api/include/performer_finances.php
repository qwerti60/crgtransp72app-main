<?php
declare(strict_types=1);

require_once __DIR__ . '/offer_status.php';

function crg_finances_payment_log_table_exists(PDO $pdo): bool
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $pdo->query('SELECT 1 FROM subscription_payment_log LIMIT 1');

        return $exists = true;
    } catch (Throwable $e) {
        return $exists = false;
    }
}

/**
 * @return array{from: string, to: string, label: string}
 */
function crg_finances_resolve_period(
    string $period,
    ?string $dateFrom = null,
    ?string $dateTo = null
): array {
    $today = new DateTimeImmutable('today');
    $to = $today->modify('+1 day');

    switch ($period) {
        case 'day':
            $from = $today;
            $label = 'За сегодня';
            break;
        case 'week':
            $from = $today->modify('-6 days');
            $label = 'За 7 дней';
            break;
        case 'month':
            $from = $today->modify('-29 days');
            $label = 'За 30 дней';
            break;
        case 'custom':
            $fromParsed = $dateFrom !== null && $dateFrom !== ''
                ? DateTimeImmutable::createFromFormat('Y-m-d', $dateFrom)
                : false;
            $toParsed = $dateTo !== null && $dateTo !== ''
                ? DateTimeImmutable::createFromFormat('Y-m-d', $dateTo)
                : false;
            if ($fromParsed instanceof DateTimeImmutable && $toParsed instanceof DateTimeImmutable) {
                if ($toParsed < $fromParsed) {
                    [$fromParsed, $toParsed] = [$toParsed, $fromParsed];
                }
                $from = $fromParsed;
                $to = $toParsed->modify('+1 day');
                $label = $from->format('d.m.Y') . ' — ' . $toParsed->format('d.m.Y');
            } else {
                $from = $today->modify('-29 days');
                $label = 'За 30 дней';
            }
            break;
        default:
            $from = $today->modify('-29 days');
            $label = 'За 30 дней';
    }

    return [
        'from' => $from->format('Y-m-d 00:00:00'),
        'to' => $to->format('Y-m-d 00:00:00'),
        'label' => $label,
    ];
}

function crg_finances_parse_money(?string $raw): float
{
    if ($raw === null || trim($raw) === '') {
        return 0.0;
    }
    $normalized = str_replace([' ', ','], ['', '.'], trim($raw));

    return is_numeric($normalized) ? (float) $normalized : 0.0;
}

function crg_finances_log_subscription_payment(
    PDO $pdo,
    int $userId,
    string $orderId,
    int $amountRub,
    int $daysAdded,
    ?string $subscriptionUntil,
    ?int $packageId = null,
    ?string $promoCode = null,
    int $discountRub = 0,
    string $paymentMethod = 'card'
): void {
    if ($userId <= 0 || $orderId === '' || !crg_finances_payment_log_table_exists($pdo)) {
        return;
    }

    try {
        // Расширенные колонки появляются после migrate_subscription_packages.sql
        try {
            $st = $pdo->prepare(
                'INSERT INTO subscription_payment_log
                 (iduser, order_id, amount_rub, days_added, package_id, promo_code, discount_rub, payment_method, paid_at, subscription_until)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)'
            );
            $st->execute([
                $userId,
                $orderId,
                max(0, $amountRub),
                max(1, $daysAdded),
                $packageId !== null && $packageId > 0 ? $packageId : null,
                $promoCode !== null && $promoCode !== '' ? $promoCode : null,
                max(0, $discountRub),
                $paymentMethod !== '' ? $paymentMethod : 'card',
                $subscriptionUntil,
            ]);
            return;
        } catch (Throwable $e) {
            // fallback без payment_method
        }

        try {
            $st = $pdo->prepare(
                'INSERT INTO subscription_payment_log
                 (iduser, order_id, amount_rub, days_added, package_id, promo_code, discount_rub, paid_at, subscription_until)
                 VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), ?)'
            );
            $st->execute([
                $userId,
                $orderId,
                max(0, $amountRub),
                max(1, $daysAdded),
                $packageId !== null && $packageId > 0 ? $packageId : null,
                $promoCode !== null && $promoCode !== '' ? $promoCode : null,
                max(0, $discountRub),
                $subscriptionUntil,
            ]);
            return;
        } catch (Throwable $e) {
            // fallback без новых колонок
        }

        $st = $pdo->prepare(
            'INSERT INTO subscription_payment_log
             (iduser, order_id, amount_rub, days_added, paid_at, subscription_until)
             VALUES (?, ?, ?, ?, NOW(), ?)'
        );
        $st->execute([
            $userId,
            $orderId,
            max(0, $amountRub),
            max(1, $daysAdded),
            $subscriptionUntil,
        ]);
    } catch (Throwable $e) {
        // ignore logging errors
    }
}

/**
 * @return list<array<string, mixed>>
 */
function crg_finances_fetch_subscription_payments(PDO $pdo, int $userId, int $limit = 100): array
{
    if ($userId <= 0 || !crg_finances_payment_log_table_exists($pdo)) {
        return [];
    }

    try {
        $st = $pdo->prepare(
            'SELECT id, order_id, amount_rub, days_added, paid_at, subscription_until
             FROM subscription_payment_log
             WHERE iduser = ?
             ORDER BY paid_at DESC, id DESC
             LIMIT ' . max(1, min(500, $limit))
        );
        $st->execute([$userId]);
        $rows = [];
        foreach ($st->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $rows[] = [
                'id' => (int) ($row['id'] ?? 0),
                'order_id' => (string) ($row['order_id'] ?? ''),
                'amount_rub' => (int) ($row['amount_rub'] ?? 0),
                'days_added' => (int) ($row['days_added'] ?? 0),
                'paid_at' => (string) ($row['paid_at'] ?? ''),
                'subscription_until' => (string) ($row['subscription_until'] ?? ''),
            ];
        }

        return $rows;
    } catch (Throwable $e) {
        return [];
    }
}

/**
 * @return array{items: list<array<string, mixed>>, total_rub: float, count: int}
 */
function crg_finances_fetch_income(
    PDO $pdo,
    int $performerId,
    string $dateFrom,
    string $dateTo
): array {
    if ($performerId <= 0) {
        return ['items' => [], 'total_rub' => 0.0, 'count' => 0];
    }

    $sql = "
        SELECT * FROM (
            SELECT og.id AS deal_id,
                   od.cena,
                   od.about,
                   og.order_id,
                   og.bd,
                   og.start_time,
                   og.end_time,
                   u.firstName,
                   u.lastName,
                   u.city,
                   'customer_order' AS deal_source,
                   COALESCE(og.end_time, og.start_time) AS income_time
            FROM offer_data od
            INNER JOIN ordersglobal og
                ON od.id = og.idoffer
                AND od.iduserp = og.user_id
                AND CAST(od.iduser AS CHAR) = CAST(og.order_id AS CHAR)
            INNER JOIN users u ON u.idusers = og.user_idok
            WHERE od.status = 1
              AND og.status = 'выполнен'
              AND og.user_id = :performer_id
              AND COALESCE(og.end_time, og.start_time) >= :from_dt
              AND COALESCE(og.end_time, og.start_time) < :to_dt

            UNION ALL

            SELECT og.id AS deal_id,
                   odf.cena,
                   odf.about,
                   og.order_id,
                   og.bd,
                   og.start_time,
                   og.end_time,
                   u.firstName,
                   u.lastName,
                   u.city,
                   'performer_ad' AS deal_source,
                   COALESCE(og.end_time, og.start_time) AS income_time
            FROM offer_dataf odf
            INNER JOIN ordersglobal og
                ON odf.id = og.idoffer
                AND CAST(odf.iduser AS CHAR) = CAST(og.order_id AS CHAR)
            INNER JOIN users u ON u.idusers = og.user_idok
            WHERE og.status = 'выполнен'
              AND og.user_id = :performer_id2
              AND COALESCE(og.end_time, og.start_time) >= :from_dt2
              AND COALESCE(og.end_time, og.start_time) < :to_dt2
        ) income
        ORDER BY income_time DESC
        LIMIT 500
    ";

    try {
        $st = $pdo->prepare($sql);
        $st->execute([
            ':performer_id' => $performerId,
            ':from_dt' => $dateFrom,
            ':to_dt' => $dateTo,
            ':performer_id2' => $performerId,
            ':from_dt2' => $dateFrom,
            ':to_dt2' => $dateTo,
        ]);

        $items = [];
        $total = 0.0;
        foreach ($st->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $amount = crg_finances_parse_money(isset($row['cena']) ? (string) $row['cena'] : '');
            $total += $amount;
            $first = trim((string) ($row['firstName'] ?? ''));
            $last = trim((string) ($row['lastName'] ?? ''));
            $counterparty = trim($first . ' ' . $last);
            $items[] = [
                'deal_id' => (int) ($row['deal_id'] ?? 0),
                'order_id' => (string) ($row['order_id'] ?? ''),
                'amount_rub' => $amount,
                'about' => (string) ($row['about'] ?? ''),
                'deal_source' => (string) ($row['deal_source'] ?? ''),
                'start_time' => (string) ($row['start_time'] ?? ''),
                'end_time' => (string) ($row['end_time'] ?? ''),
                'income_time' => (string) ($row['income_time'] ?? ''),
                'counterparty' => $counterparty !== '' ? $counterparty : 'Заказчик',
                'city' => (string) ($row['city'] ?? ''),
                'bd' => (int) ($row['bd'] ?? 0),
            ];
        }

        return [
            'items' => $items,
            'total_rub' => round($total, 2),
            'count' => count($items),
        ];
    } catch (Throwable $e) {
        return ['items' => [], 'total_rub' => 0.0, 'count' => 0];
    }
}

/**
 * @return array<string, mixed>
 */
function crg_finances_build_report(
    PDO $pdo,
    int $performerId,
    string $period,
    ?string $dateFrom = null,
    ?string $dateTo = null
): array {
    $range = crg_finances_resolve_period($period, $dateFrom, $dateTo);
    $payments = crg_finances_fetch_subscription_payments($pdo, $performerId);
    $paymentsTotal = 0;
    foreach ($payments as $p) {
        $paymentsTotal += (int) ($p['amount_rub'] ?? 0);
    }

    $income = crg_finances_fetch_income(
        $pdo,
        $performerId,
        $range['from'],
        $range['to']
    );

    return [
        'period' => [
            'key' => $period,
            'label' => $range['label'],
            'from' => $range['from'],
            'to' => $range['to'],
        ],
        'subscription_payments' => $payments,
        'subscription_total_rub' => $paymentsTotal,
        'income_items' => $income['items'],
        'income_total_rub' => $income['total_rub'],
        'income_count' => $income['count'],
    ];
}

/**
 * Суммарный оборот выполненных сделок всех исполнителей за период (GMV).
 *
 * @return array{items_count: int, total_rub: float, by_day: list<array{date: string, count: int, total_rub: float}>}
 */
function crg_finances_fetch_platform_income(PDO $pdo, string $dateFrom, string $dateTo): array
{
    $sql = "
        SELECT DATE(income_time) AS d,
               COUNT(*) AS cnt,
               SUM(amount) AS total
        FROM (
            SELECT COALESCE(og.end_time, og.start_time) AS income_time,
                   CAST(REPLACE(REPLACE(TRIM(od.cena), ' ', ''), ',', '.') AS DECIMAL(14,2)) AS amount
            FROM offer_data od
            INNER JOIN ordersglobal og
                ON od.id = og.idoffer
                AND od.iduserp = og.user_id
                AND CAST(od.iduser AS CHAR) = CAST(og.order_id AS CHAR)
            WHERE od.status = 1
              AND og.status = 'выполнен'
              AND COALESCE(og.end_time, og.start_time) >= :from_dt
              AND COALESCE(og.end_time, og.start_time) < :to_dt

            UNION ALL

            SELECT COALESCE(og.end_time, og.start_time) AS income_time,
                   CAST(REPLACE(REPLACE(TRIM(odf.cena), ' ', ''), ',', '.') AS DECIMAL(14,2)) AS amount
            FROM offer_dataf odf
            INNER JOIN ordersglobal og
                ON odf.id = og.idoffer
                AND CAST(odf.iduser AS CHAR) = CAST(og.order_id AS CHAR)
            WHERE og.status = 'выполнен'
              AND COALESCE(og.end_time, og.start_time) >= :from_dt2
              AND COALESCE(og.end_time, og.start_time) < :to_dt2
        ) income
        WHERE amount IS NOT NULL
        GROUP BY DATE(income_time)
        ORDER BY d
    ";

    try {
        $st = $pdo->prepare($sql);
        $st->execute([
            ':from_dt' => $dateFrom,
            ':to_dt' => $dateTo,
            ':from_dt2' => $dateFrom,
            ':to_dt2' => $dateTo,
        ]);

        $byDay = [];
        $total = 0.0;
        $count = 0;
        foreach ($st->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $dayTotal = (float) ($row['total'] ?? 0);
            $dayCount = (int) ($row['cnt'] ?? 0);
            $total += $dayTotal;
            $count += $dayCount;
            $byDay[] = [
                'date' => (string) ($row['d'] ?? ''),
                'count' => $dayCount,
                'total_rub' => round($dayTotal, 2),
            ];
        }

        return [
            'items_count' => $count,
            'total_rub' => round($total, 2),
            'by_day' => $byDay,
        ];
    } catch (Throwable $e) {
        return ['items_count' => 0, 'total_rub' => 0.0, 'by_day' => []];
    }
}

/**
 * @return list<array<string, mixed>>
 */
function crg_finances_fetch_payments_in_range(PDO $pdo, string $dateFrom, string $dateTo, int $limit = 5000): array
{
    if (!crg_finances_payment_log_table_exists($pdo)) {
        return [];
    }

    try {
        $st = $pdo->prepare(
            'SELECT id, iduser, order_id, amount_rub, days_added, paid_at, subscription_until,
                    COALESCE(payment_method, \'card\') AS payment_method
             FROM subscription_payment_log
             WHERE paid_at >= ? AND paid_at < ?
             ORDER BY paid_at DESC, id DESC
             LIMIT ' . max(1, min(10000, $limit))
        );
        $st->execute([$dateFrom, $dateTo]);

        return $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        return [];
    }
}
