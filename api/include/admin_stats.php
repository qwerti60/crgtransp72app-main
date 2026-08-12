<?php
declare(strict_types=1);

function crg_admin_stats_table_exists(PDO $pdo, string $table): bool
{
    static $cache = [];
    if (array_key_exists($table, $cache)) {
        return $cache[$table];
    }
    try {
        $st = $pdo->query('SHOW TABLES LIKE ' . $pdo->quote($table));

        return $cache[$table] = $st->fetch() !== false;
    } catch (Throwable $e) {
        return $cache[$table] = false;
    }
}

function crg_admin_stats_column_exists(PDO $pdo, string $table, string $column): bool
{
    static $cache = [];
    $key = $table . '.' . $column;
    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }
    if (!crg_admin_stats_table_exists($pdo, $table)) {
        return $cache[$key] = false;
    }
    try {
        $st = $pdo->query("SHOW COLUMNS FROM `{$table}` LIKE " . $pdo->quote($column));

        return $cache[$key] = $st->fetch() !== false;
    } catch (Throwable $e) {
        return $cache[$key] = false;
    }
}

/**
 * @template T
 * @param callable(): T $fn
 * @return T|null
 */
function crg_admin_stats_try(callable $fn): mixed
{
    try {
        return $fn();
    } catch (Throwable $e) {
        return null;
    }
}

/**
 * @param array{period?: string, from?: string|null, to?: string|null} $opts
 * @return array<string, mixed>
 */
function crg_admin_stats_dashboard(PDO $pdo, array $opts = []): array
{
    tp_admin_web_require_include('admin_users.php');
    tp_admin_web_require_include('admin_ads.php');
    tp_admin_web_require_include('admin_subscriptions.php');
    if (is_readable(__DIR__ . '/performer_finances.php')) {
        require_once __DIR__ . '/performer_finances.php';
    }

    $period = isset($opts['period']) ? trim((string) $opts['period']) : 'month';
    if (!in_array($period, ['day', 'week', 'month', 'custom', 'all'], true)) {
        $period = 'month';
    }
    $dateFrom = isset($opts['from']) ? trim((string) $opts['from']) : '';
    $dateTo = isset($opts['to']) ? trim((string) $opts['to']) : '';

    $out = [
        'generated_at' => date('Y-m-d H:i:s'),
        'period' => $period,
        'kpi' => [],
        'users_by_role' => [],
        'users_by_city' => [],
        'registrations_30d' => [],
        'performer_ads' => [],
        'customer_requests' => [],
        'subscriptions' => [],
        'offers' => [],
        'proposals' => [],
        'reviews_performers' => [],
        'reviews_customers' => [],
        'cities_ref' => 0,
        'orders_global' => [],
        'tariff' => null,
        'subscription_analytics' => [],
        'platform_finances' => [],
        'funnel' => [],
    ];

    if (crg_admin_stats_table_exists($pdo, 'users')) {
        $out['kpi']['users_total'] = (int) crg_admin_stats_try(
            static fn (): int => (int) $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn()
        );

        $rows = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                'SELECT rollNum, COUNT(*) AS cnt FROM users WHERE rollNum IS NOT NULL GROUP BY rollNum ORDER BY rollNum'
            );

            return $st->fetchAll();
        });
        if (is_array($rows)) {
            foreach ($rows as $r) {
                $roll = (int) ($r['rollNum'] ?? 0);
                $out['users_by_role'][] = [
                    'roll' => $roll,
                    'label' => crg_admin_user_roll_label($roll),
                    'count' => (int) ($r['cnt'] ?? 0),
                ];
            }
        }

        $rows = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                "SELECT city, COUNT(*) AS cnt FROM users
                 WHERE city IS NOT NULL AND TRIM(city) != ''
                 GROUP BY city ORDER BY cnt DESC LIMIT 15"
            );

            return $st->fetchAll();
        });
        if (is_array($rows)) {
            foreach ($rows as $r) {
                $out['users_by_city'][] = [
                    'city' => (string) ($r['city'] ?? ''),
                    'count' => (int) ($r['cnt'] ?? 0),
                ];
            }
        }

        if (crg_admin_stats_column_exists($pdo, 'users', 'created_at')) {
            $rows = crg_admin_stats_try(static function () use ($pdo): array {
                $st = $pdo->query(
                    "SELECT DATE(created_at) AS d, COUNT(*) AS cnt
                     FROM users
                     WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 29 DAY)
                     GROUP BY DATE(created_at)
                     ORDER BY d"
                );

                return $st->fetchAll();
            });
            if (is_array($rows)) {
                foreach ($rows as $r) {
                    $out['registrations_30d'][] = [
                        'date' => (string) ($r['d'] ?? ''),
                        'count' => (int) ($r['cnt'] ?? 0),
                    ];
                }
            }

            $recent = crg_admin_stats_try(static function () use ($pdo): int {
                $st = $pdo->query(
                    'SELECT COUNT(*) FROM users WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)'
                );

                return (int) $st->fetchColumn();
            });
            if ($recent !== null) {
                $out['kpi']['users_30d'] = $recent;
            }
        }

        if (crg_admin_stats_column_exists($pdo, 'users', 'fcm_token')) {
            $push = crg_admin_stats_try(static function () use ($pdo): int {
                $st = $pdo->query(
                    "SELECT COUNT(*) FROM users WHERE fcm_token IS NOT NULL AND TRIM(fcm_token) != ''"
                );

                return (int) $st->fetchColumn();
            });
            if ($push !== null) {
                $out['kpi']['users_push'] = $push;
            }
        }
    }

    $adsPending = 0;
    $adsPublished = 0;
    $adsTotal = 0;
    foreach (crg_admin_performer_ad_types() as $type => $cfg) {
        $table = (string) ($cfg['table'] ?? '');
        if (!crg_admin_stats_table_exists($pdo, $table)) {
            continue;
        }
        $row = crg_admin_stats_try(static function () use ($pdo, $table): array {
            $st = $pdo->query(
                "SELECT COUNT(*) AS total,
                        SUM(CASE WHEN flag = 1 THEN 1 ELSE 0 END) AS published,
                        SUM(CASE WHEN flag = 0 THEN 1 ELSE 0 END) AS pending
                 FROM `{$table}`"
            );

            return $st->fetch() ?: [];
        });
        if (!is_array($row)) {
            continue;
        }
        $total = (int) ($row['total'] ?? 0);
        $published = (int) ($row['published'] ?? 0);
        $pending = (int) ($row['pending'] ?? 0);
        $adsTotal += $total;
        $adsPublished += $published;
        $adsPending += $pending;
        $out['performer_ads'][] = [
            'type' => $type,
            'label' => (string) ($cfg['label'] ?? $type),
            'total' => $total,
            'published' => $published,
            'pending' => $pending,
        ];
    }
    $out['kpi']['performer_ads_total'] = $adsTotal;
    $out['kpi']['performer_ads_published'] = $adsPublished;
    $out['kpi']['performer_ads_pending'] = $adsPending;

    $reqTotal = 0;
    $reqActive = 0;
    foreach (crg_admin_customer_ad_types() as $type => $cfg) {
        $table = (string) ($cfg['table'] ?? '');
        if (!crg_admin_stats_table_exists($pdo, $table)) {
            continue;
        }
        $row = crg_admin_stats_try(static function () use ($pdo, $table): array {
            $st = $pdo->query(
                "SELECT COUNT(*) AS total,
                        SUM(CASE WHEN enddatez >= CURDATE() AND enddatez <> '0000-00-00' THEN 1 ELSE 0 END) AS active
                 FROM `{$table}`"
            );

            return $st->fetch() ?: [];
        });
        if (!is_array($row)) {
            continue;
        }
        $total = (int) ($row['total'] ?? 0);
        $active = (int) ($row['active'] ?? 0);
        $reqTotal += $total;
        $reqActive += $active;
        $out['customer_requests'][] = [
            'type' => $type,
            'label' => (string) ($cfg['label'] ?? $type),
            'total' => $total,
            'active' => $active,
        ];
    }
    $out['kpi']['customer_requests_total'] = $reqTotal;
    $out['kpi']['customer_requests_active'] = $reqActive;

    if (crg_admin_subscriptions_table_exists($pdo)) {
        $sub = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                'SELECT
                    SUM(CASE WHEN s.date >= CURDATE() THEN 1 ELSE 0 END) AS active,
                    SUM(CASE WHEN s.date < CURDATE() THEN 1 ELSE 0 END) AS expired,
                    SUM(CASE WHEN s.date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS ending_7,
                    SUM(CASE WHEN s.count > 1 THEN 1 ELSE 0 END) AS renewed,
                    COUNT(*) AS with_sub
                 FROM (
                    SELECT iduser, MAX(id) AS max_id FROM subscriptions GROUP BY iduser
                 ) t
                 JOIN subscriptions s ON s.id = t.max_id'
            );

            return $st->fetch() ?: [];
        });
        if (is_array($sub)) {
            $out['subscriptions'] = [
                'active' => (int) ($sub['active'] ?? 0),
                'expired' => (int) ($sub['expired'] ?? 0),
                'ending_7' => (int) ($sub['ending_7'] ?? 0),
                'renewed' => (int) ($sub['renewed'] ?? 0),
                'with_sub' => (int) ($sub['with_sub'] ?? 0),
            ];
            $out['kpi']['subscriptions_active'] = (int) ($sub['active'] ?? 0);
            $out['kpi']['subscriptions_expired'] = (int) ($sub['expired'] ?? 0);
        }

        $performers = crg_admin_stats_try(static function () use ($pdo): int {
            $st = $pdo->query('SELECT COUNT(*) FROM users WHERE rollNum IN (2, 3, 4)');

            return (int) $st->fetchColumn();
        });
        if ($performers !== null && isset($out['subscriptions']['with_sub'])) {
            $out['subscriptions']['performers_total'] = $performers;
            $out['subscriptions']['never_subscribed'] = max(0, $performers - (int) $out['subscriptions']['with_sub']);
        }
    }

    $tariff = crg_admin_subscription_config($pdo);
    if ($tariff !== null) {
        $out['tariff'] = $tariff;
        if (isset($out['kpi']['subscriptions_active'])) {
            $out['subscriptions']['est_revenue_rub'] =
                (int) $out['kpi']['subscriptions_active'] * (int) $tariff['price_rub'];
        }
    }

    if (crg_admin_stats_table_exists($pdo, 'offer_data')) {
        $rows = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                'SELECT bd,
                        COUNT(*) AS total,
                        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS accepted,
                        ROUND(AVG(cena), 0) AS avg_price
                 FROM offer_data
                 GROUP BY bd
                 ORDER BY bd'
            );

            return $st->fetchAll();
        });
        $offerTotal = 0;
        $offerAccepted = 0;
        if (is_array($rows)) {
            $bdLabels = [1 => 'Грузоперевозки', 2 => 'Спецтехника', 3 => 'Грузчики'];
            foreach ($rows as $r) {
                $bd = (int) ($r['bd'] ?? 0);
                $total = (int) ($r['total'] ?? 0);
                $accepted = (int) ($r['accepted'] ?? 0);
                $offerTotal += $total;
                $offerAccepted += $accepted;
                $out['offers'][] = [
                    'bd' => $bd,
                    'label' => $bdLabels[$bd] ?? ('bd=' . $bd),
                    'total' => $total,
                    'accepted' => $accepted,
                    'avg_price' => (int) ($r['avg_price'] ?? 0),
                ];
            }
        }
        $out['kpi']['offers_total'] = $offerTotal;
        $out['kpi']['offers_accepted'] = $offerAccepted;

        if (crg_admin_stats_column_exists($pdo, 'offer_data', 'timestamp')) {
            $recent = crg_admin_stats_try(static function () use ($pdo): int {
                $st = $pdo->query(
                    'SELECT COUNT(*) FROM offer_data WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)'
                );

                return (int) $st->fetchColumn();
            });
            if ($recent !== null) {
                $out['kpi']['offers_30d'] = $recent;
            }
        }
    }

    if (crg_admin_stats_table_exists($pdo, 'offer_dataf')) {
        $rows = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                'SELECT bd, COUNT(*) AS total, ROUND(AVG(cena), 0) AS avg_price
                 FROM offer_dataf
                 GROUP BY bd
                 ORDER BY bd'
            );

            return $st->fetchAll();
        });
        $propTotal = 0;
        if (is_array($rows)) {
            $bdLabels = [1 => 'Грузоперевозки', 2 => 'Спецтехника', 3 => 'Грузчики'];
            foreach ($rows as $r) {
                $bd = (int) ($r['bd'] ?? 0);
                $total = (int) ($r['total'] ?? 0);
                $propTotal += $total;
                $out['proposals'][] = [
                    'bd' => $bd,
                    'label' => $bdLabels[$bd] ?? ('bd=' . $bd),
                    'total' => $total,
                    'avg_price' => (int) ($r['avg_price'] ?? 0),
                ];
            }
        }
        $out['kpi']['proposals_total'] = $propTotal;
    }

    if (crg_admin_stats_table_exists($pdo, 'reviewsisp')) {
        $row = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                'SELECT COUNT(*) AS cnt,
                        ROUND(AVG(rating), 2) AS avg_rating,
                        SUM(rating = 5) AS r5,
                        SUM(rating = 4) AS r4,
                        SUM(rating = 3) AS r3,
                        SUM(rating = 2) AS r2,
                        SUM(rating = 1) AS r1
                 FROM reviewsisp'
            );

            return $st->fetch() ?: [];
        });
        if (is_array($row)) {
            $out['reviews_performers'] = [
                'count' => (int) ($row['cnt'] ?? 0),
                'avg' => (float) ($row['avg_rating'] ?? 0),
                'stars' => [
                    5 => (int) ($row['r5'] ?? 0),
                    4 => (int) ($row['r4'] ?? 0),
                    3 => (int) ($row['r3'] ?? 0),
                    2 => (int) ($row['r2'] ?? 0),
                    1 => (int) ($row['r1'] ?? 0),
                ],
            ];
            $out['kpi']['reviews_performers'] = (int) ($row['cnt'] ?? 0);
        }
    }

    if (crg_admin_stats_table_exists($pdo, 'reviews')) {
        $row = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                'SELECT COUNT(*) AS cnt,
                        ROUND(AVG(rating), 2) AS avg_rating,
                        SUM(rating = 5) AS r5,
                        SUM(rating = 4) AS r4,
                        SUM(rating = 3) AS r3,
                        SUM(rating = 2) AS r2,
                        SUM(rating = 1) AS r1
                 FROM reviews'
            );

            return $st->fetch() ?: [];
        });
        if (is_array($row)) {
            $out['reviews_customers'] = [
                'count' => (int) ($row['cnt'] ?? 0),
                'avg' => (float) ($row['avg_rating'] ?? 0),
                'stars' => [
                    5 => (int) ($row['r5'] ?? 0),
                    4 => (int) ($row['r4'] ?? 0),
                    3 => (int) ($row['r3'] ?? 0),
                    2 => (int) ($row['r2'] ?? 0),
                    1 => (int) ($row['r1'] ?? 0),
                ],
            ];
            $out['kpi']['reviews_customers'] = (int) ($row['cnt'] ?? 0);
        }
    }

    if (crg_admin_stats_table_exists($pdo, 'cities')) {
        $cnt = crg_admin_stats_try(static function () use ($pdo): int {
            return (int) $pdo->query('SELECT COUNT(*) FROM cities')->fetchColumn();
        });
        if ($cnt !== null) {
            $out['cities_ref'] = $cnt;
        }
    }

    if (crg_admin_stats_table_exists($pdo, 'ordersglobal')) {
        $row = crg_admin_stats_try(static function () use ($pdo): array {
            $st = $pdo->query(
                "SELECT
                    COUNT(*) AS total,
                    SUM(status = 'выполняется') AS in_progress,
                    SUM(status = 'выполнен') AS completed,
                    SUM(status = 'отменен') AS cancelled
                 FROM ordersglobal"
            );

            return $st->fetch() ?: [];
        });
        if (is_array($row)) {
            $out['orders_global'] = [
                'total' => (int) ($row['total'] ?? 0),
                'in_progress' => (int) ($row['in_progress'] ?? 0),
                'completed' => (int) ($row['completed'] ?? 0),
                'cancelled' => (int) ($row['cancelled'] ?? 0),
            ];
            $out['kpi']['orders_global'] = (int) ($row['total'] ?? 0);
        }
    }

    $out['subscription_analytics'] = crg_admin_stats_subscription_analytics(
        $pdo,
        $period,
        $dateFrom !== '' ? $dateFrom : null,
        $dateTo !== '' ? $dateTo : null
    );
    $out['platform_finances'] = crg_admin_stats_platform_finances(
        $pdo,
        $period,
        $dateFrom !== '' ? $dateFrom : null,
        $dateTo !== '' ? $dateTo : null
    );

    $sa = $out['subscription_analytics'];
    if (($sa['period']['revenue_rub'] ?? null) !== null) {
        $out['kpi']['subscription_revenue_period'] = (int) ($sa['period']['revenue_rub'] ?? 0);
    }
    if (($sa['all_time']['revenue_rub'] ?? null) !== null) {
        $out['kpi']['subscription_revenue_all_time'] = (int) ($sa['all_time']['revenue_rub'] ?? 0);
    }
    $pf = $out['platform_finances'];
    if (isset($pf['deals_gmv_rub'])) {
        $out['kpi']['deals_gmv_period'] = (int) round((float) $pf['deals_gmv_rub']);
    }
    if (isset($pf['deals_count'])) {
        $out['kpi']['deals_count_period'] = (int) $pf['deals_count'];
    }

    $out['funnel'] = crg_admin_stats_funnel(
        $pdo,
        $period,
        $dateFrom !== '' ? $dateFrom : '',
        $dateTo !== '' ? $dateTo : ''
    );

    return $out;
}

/**
 * @return array<string, mixed>
 */
function crg_admin_stats_subscription_analytics(
    PDO $pdo,
    string $period,
    ?string $dateFrom = null,
    ?string $dateTo = null
): array {
    $empty = [
        'period_info' => ['key' => $period, 'label' => '', 'from' => '', 'to' => ''],
        'period' => [],
        'all_time' => [],
        'snapshot' => [],
        'payments_by_day' => [],
        'recent_payments' => [],
        'has_payment_log' => false,
    ];

    if (!function_exists('crg_finances_resolve_period')) {
        if (!is_readable(__DIR__ . '/performer_finances.php')) {
            return $empty;
        }
        require_once __DIR__ . '/performer_finances.php';
    }

    $hasLog = crg_finances_payment_log_table_exists($pdo);
    $empty['has_payment_log'] = $hasLog;

    if ($period === 'all') {
        $range = [
            'from' => '1970-01-01 00:00:00',
            'to' => date('Y-m-d 00:00:00', strtotime('+1 day')),
            'label' => 'За всё время',
        ];
    } else {
        $range = crg_finances_resolve_period($period, $dateFrom, $dateTo);
    }

    $empty['period_info'] = [
        'key' => $period,
        'label' => $range['label'],
        'from' => $range['from'],
        'to' => $range['to'],
    ];

    if ($hasLog) {
        $empty['period'] = crg_admin_stats_payment_metrics($pdo, $range['from'], $range['to']);
        $empty['all_time'] = crg_admin_stats_payment_metrics(
            $pdo,
            '1970-01-01 00:00:00',
            date('Y-m-d 00:00:00', strtotime('+1 day'))
        );
        $empty['payments_by_day'] = crg_admin_stats_payments_by_day($pdo, $range['from'], $range['to']);
        $empty['recent_payments'] = crg_admin_stats_recent_payments($pdo, $range['from'], $range['to'], 15);
    }

    if (crg_admin_subscriptions_table_exists($pdo)) {
        $empty['snapshot'] = crg_admin_stats_subscription_snapshot($pdo, $range['from'], $range['to']);
    }

    return $empty;
}

/**
 * @return array<string, int|float>
 */
function crg_admin_stats_payment_metrics(PDO $pdo, string $from, string $to): array
{
    $base = [
        'revenue_rub' => 0,
        'payments_count' => 0,
        'unique_payers' => 0,
        'new_subscriptions' => 0,
        'renewals' => 0,
        'avg_payment_rub' => 0.0,
    ];

    if (!crg_finances_payment_log_table_exists($pdo)) {
        return $base;
    }

    $row = crg_admin_stats_try(static function () use ($pdo, $from, $to): array {
        $st = $pdo->prepare(
            'SELECT COUNT(*) AS cnt,
                    COUNT(DISTINCT iduser) AS payers,
                    COALESCE(SUM(amount_rub), 0) AS revenue,
                    COALESCE(ROUND(AVG(amount_rub), 2), 0) AS avg_rub
             FROM subscription_payment_log
             WHERE paid_at >= ? AND paid_at < ?'
        );
        $st->execute([$from, $to]);

        return $st->fetch() ?: [];
    });
    if (!is_array($row)) {
        return $base;
    }

    $base['payments_count'] = (int) ($row['cnt'] ?? 0);
    $base['unique_payers'] = (int) ($row['payers'] ?? 0);
    $base['revenue_rub'] = (int) ($row['revenue'] ?? 0);
    $base['avg_payment_rub'] = (float) ($row['avg_rub'] ?? 0);

    $typeRow = crg_admin_stats_try(static function () use ($pdo, $from, $to): array {
        $st = $pdo->prepare(
            'SELECT
                SUM(CASE WHEN prior_cnt = 0 THEN 1 ELSE 0 END) AS new_cnt,
                SUM(CASE WHEN prior_cnt > 0 THEN 1 ELSE 0 END) AS renewal_cnt
             FROM (
                SELECT p.id,
                       (SELECT COUNT(*) FROM subscription_payment_log p2
                        WHERE p2.iduser = p.iduser
                          AND (p2.paid_at < p.paid_at OR (p2.paid_at = p.paid_at AND p2.id < p.id))
                       ) AS prior_cnt
                FROM subscription_payment_log p
                WHERE p.paid_at >= ? AND p.paid_at < ?
             ) t'
        );
        $st->execute([$from, $to]);

        return $st->fetch() ?: [];
    });
    if (is_array($typeRow)) {
        $base['new_subscriptions'] = (int) ($typeRow['new_cnt'] ?? 0);
        $base['renewals'] = (int) ($typeRow['renewal_cnt'] ?? 0);
    }

    return $base;
}

/**
 * @return list<array{date: string, count: int, revenue_rub: int, new_count: int, renewal_count: int}>
 */
function crg_admin_stats_payments_by_day(PDO $pdo, string $from, string $to): array
{
    if (!crg_finances_payment_log_table_exists($pdo)) {
        return [];
    }

    $rows = crg_admin_stats_try(static function () use ($pdo, $from, $to): array {
        $st = $pdo->prepare(
            'SELECT DATE(paid_at) AS d,
                    COUNT(*) AS cnt,
                    COALESCE(SUM(amount_rub), 0) AS revenue,
                    SUM(CASE WHEN prior_cnt = 0 THEN 1 ELSE 0 END) AS new_cnt,
                    SUM(CASE WHEN prior_cnt > 0 THEN 1 ELSE 0 END) AS renewal_cnt
             FROM (
                SELECT p.paid_at, p.amount_rub,
                       (SELECT COUNT(*) FROM subscription_payment_log p2
                        WHERE p2.iduser = p.iduser
                          AND (p2.paid_at < p.paid_at OR (p2.paid_at = p.paid_at AND p2.id < p.id))
                       ) AS prior_cnt
                FROM subscription_payment_log p
                WHERE p.paid_at >= ? AND p.paid_at < ?
             ) t
             GROUP BY DATE(paid_at)
             ORDER BY d'
        );
        $st->execute([$from, $to]);

        return $st->fetchAll() ?: [];
    });
    if (!is_array($rows)) {
        return [];
    }

    $out = [];
    foreach ($rows as $r) {
        $out[] = [
            'date' => (string) ($r['d'] ?? ''),
            'count' => (int) ($r['cnt'] ?? 0),
            'revenue_rub' => (int) ($r['revenue'] ?? 0),
            'new_count' => (int) ($r['new_cnt'] ?? 0),
            'renewal_count' => (int) ($r['renewal_cnt'] ?? 0),
        ];
    }

    return $out;
}

/**
 * @return list<array<string, mixed>>
 */
function crg_admin_stats_recent_payments(PDO $pdo, string $from, string $to, int $limit = 15): array
{
    if (!crg_finances_payment_log_table_exists($pdo)) {
        return [];
    }

    $rows = crg_admin_stats_try(static function () use ($pdo, $from, $to, $limit): array {
        $st = $pdo->prepare(
            'SELECT p.id, p.iduser, p.order_id, p.amount_rub, p.days_added, p.paid_at,
                    p.subscription_until, u.firstName, u.lastName, u.city,
                    (SELECT COUNT(*) FROM subscription_payment_log p2
                     WHERE p2.iduser = p.iduser
                       AND (p2.paid_at < p.paid_at OR (p2.paid_at = p.paid_at AND p2.id < p.id))
                    ) AS prior_cnt
             FROM subscription_payment_log p
             LEFT JOIN users u ON u.idusers = p.iduser
             WHERE p.paid_at >= ? AND p.paid_at < ?
             ORDER BY p.paid_at DESC, p.id DESC
             LIMIT ' . max(1, min(50, $limit))
        );
        $st->execute([$from, $to]);

        return $st->fetchAll() ?: [];
    });
    if (!is_array($rows)) {
        return [];
    }

    $out = [];
    foreach ($rows as $r) {
        $first = trim((string) ($r['firstName'] ?? ''));
        $last = trim((string) ($r['lastName'] ?? ''));
        $name = trim($first . ' ' . $last);
        $out[] = [
            'id' => (int) ($r['id'] ?? 0),
            'iduser' => (int) ($r['iduser'] ?? 0),
            'user_name' => $name !== '' ? $name : ('ID ' . (int) ($r['iduser'] ?? 0)),
            'city' => (string) ($r['city'] ?? ''),
            'order_id' => (string) ($r['order_id'] ?? ''),
            'amount_rub' => (int) ($r['amount_rub'] ?? 0),
            'days_added' => (int) ($r['days_added'] ?? 0),
            'paid_at' => (string) ($r['paid_at'] ?? ''),
            'subscription_until' => (string) ($r['subscription_until'] ?? ''),
            'is_renewal' => (int) ($r['prior_cnt'] ?? 0) > 0,
        ];
    }

    return $out;
}

/**
 * @return array<string, int|float>
 */
function crg_admin_stats_subscription_snapshot(PDO $pdo, string $from, string $to): array
{
    $snap = [
        'active' => 0,
        'expired' => 0,
        'ending_7' => 0,
        'renewed_users' => 0,
        'never_subscribed' => 0,
        'not_renewed' => 0,
        'expired_in_period' => 0,
        'performers_total' => 0,
        'with_sub' => 0,
        'conversion_pct' => 0.0,
        'renewal_rate_pct' => 0.0,
    ];

    $sub = crg_admin_stats_try(static function () use ($pdo): array {
        $st = $pdo->query(
            'SELECT
                SUM(CASE WHEN s.date >= CURDATE() THEN 1 ELSE 0 END) AS active,
                SUM(CASE WHEN s.date < CURDATE() THEN 1 ELSE 0 END) AS expired,
                SUM(CASE WHEN s.date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS ending_7,
                SUM(CASE WHEN s.count > 1 THEN 1 ELSE 0 END) AS renewed,
                SUM(CASE WHEN s.date < CURDATE() AND s.count >= 1 THEN 1 ELSE 0 END) AS not_renewed,
                COUNT(*) AS with_sub
             FROM (
                SELECT iduser, MAX(id) AS max_id FROM subscriptions GROUP BY iduser
             ) t
             JOIN subscriptions s ON s.id = t.max_id'
        );

        return $st->fetch() ?: [];
    });
    if (is_array($sub)) {
        $snap['active'] = (int) ($sub['active'] ?? 0);
        $snap['expired'] = (int) ($sub['expired'] ?? 0);
        $snap['ending_7'] = (int) ($sub['ending_7'] ?? 0);
        $snap['renewed_users'] = (int) ($sub['renewed'] ?? 0);
        $snap['not_renewed'] = (int) ($sub['not_renewed'] ?? 0);
        $snap['with_sub'] = (int) ($sub['with_sub'] ?? 0);
    }

    $performers = crg_admin_stats_try(static function () use ($pdo): int {
        $st = $pdo->query('SELECT COUNT(*) FROM users WHERE rollNum IN (2, 3, 4)');

        return (int) $st->fetchColumn();
    });
    if ($performers !== null) {
        $snap['performers_total'] = $performers;
        $snap['never_subscribed'] = max(0, $performers - $snap['with_sub']);
        if ($performers > 0) {
            $snap['conversion_pct'] = round(100 * $snap['with_sub'] / $performers, 1);
        }
    }
    if ($snap['with_sub'] > 0) {
        $snap['renewal_rate_pct'] = round(100 * $snap['renewed_users'] / $snap['with_sub'], 1);
    }

    $fromDate = substr($from, 0, 10);
    $toDate = date('Y-m-d', strtotime(substr($to, 0, 10) . ' -1 day'));
    $expiredInPeriod = crg_admin_stats_try(static function () use ($pdo, $fromDate, $toDate): int {
        $st = $pdo->prepare(
            'SELECT COUNT(*) FROM (
                SELECT s.iduser, s.date
                FROM (
                    SELECT iduser, MAX(id) AS max_id FROM subscriptions GROUP BY iduser
                ) t
                JOIN subscriptions s ON s.id = t.max_id
             ) x
             WHERE x.date >= ? AND x.date <= ?'
        );
        $st->execute([$fromDate, $toDate]);

        return (int) $st->fetchColumn();
    });
    if ($expiredInPeriod !== null) {
        $snap['expired_in_period'] = $expiredInPeriod;
    }

    return $snap;
}

/**
 * @return array<string, mixed>
 */
function crg_admin_stats_platform_finances(
    PDO $pdo,
    string $period,
    ?string $dateFrom = null,
    ?string $dateTo = null
): array
{
    $out = [
        'period_info' => ['key' => $period, 'label' => '', 'from' => '', 'to' => ''],
        'subscription_revenue_rub' => 0,
        'deals_gmv_rub' => 0.0,
        'deals_count' => 0,
        'deals_by_day' => [],
        'total_earned_rub' => 0.0,
    ];

    if (!function_exists('crg_finances_resolve_period')) {
        if (!is_readable(__DIR__ . '/performer_finances.php')) {
            return $out;
        }
        require_once __DIR__ . '/performer_finances.php';
    }

    if ($period === 'all') {
        $range = [
            'from' => '1970-01-01 00:00:00',
            'to' => date('Y-m-d 00:00:00', strtotime('+1 day')),
            'label' => 'За всё время',
        ];
    } else {
        $range = crg_finances_resolve_period($period, $dateFrom, $dateTo);
    }

    $out['period_info'] = [
        'key' => $period,
        'label' => $range['label'],
        'from' => $range['from'],
        'to' => $range['to'],
    ];

    if (crg_finances_payment_log_table_exists($pdo)) {
        $metrics = crg_admin_stats_payment_metrics($pdo, $range['from'], $range['to']);
        $out['subscription_revenue_rub'] = (int) ($metrics['revenue_rub'] ?? 0);
    }

    if (crg_admin_stats_table_exists($pdo, 'ordersglobal')) {
        $deals = crg_finances_fetch_platform_income($pdo, $range['from'], $range['to']);
        $out['deals_gmv_rub'] = (float) ($deals['total_rub'] ?? 0);
        $out['deals_count'] = (int) ($deals['items_count'] ?? 0);
        $out['deals_by_day'] = $deals['by_day'] ?? [];
    }

    $out['total_earned_rub'] = round(
        (float) $out['subscription_revenue_rub'] + (float) $out['deals_gmv_rub'],
        2
    );

    return $out;
}

/**
 * Воронка: регистрации → объявления → отклики → сделки → оплата подписки.
 *
 * @return array<string, mixed>
 */
function crg_admin_stats_funnel(
    PDO $pdo,
    string $period,
    string $dateFrom = '',
    string $dateTo = ''
): array {
    $from = '1970-01-01 00:00:00';
    $to = date('Y-m-d 23:59:59');

    if ($period === 'custom' && $dateFrom !== '' && $dateTo !== '') {
        $from = substr($dateFrom, 0, 10) . ' 00:00:00';
        $to = substr($dateTo, 0, 10) . ' 23:59:59';
    } elseif ($period === 'day') {
        $from = date('Y-m-d 00:00:00');
    } elseif ($period === 'week') {
        $from = date('Y-m-d 00:00:00', strtotime('-6 days'));
    } elseif ($period === 'month') {
        $from = date('Y-m-d 00:00:00', strtotime('-29 days'));
    } elseif ($period !== 'all') {
        $from = date('Y-m-d 00:00:00', strtotime('-29 days'));
    }

    $steps = [
        ['key' => 'registrations', 'label' => 'Регистрации', 'count' => 0],
        ['key' => 'first_ad', 'label' => 'Первое объявление/заявка', 'count' => 0],
        ['key' => 'offers', 'label' => 'Отклики (offer)', 'count' => 0],
        ['key' => 'deals', 'label' => 'Завершённые сделки', 'count' => 0],
        ['key' => 'subscription_paid', 'label' => 'Оплата подписки', 'count' => 0],
    ];

    if (crg_admin_stats_table_exists($pdo, 'users')) {
        $hasCreated = crg_admin_stats_column_exists($pdo, 'users', 'created_at');
        if ($hasCreated) {
            $st = $pdo->prepare('SELECT COUNT(*) FROM users WHERE created_at >= ? AND created_at <= ?');
            $st->execute([$from, $to]);
            $steps[0]['count'] = (int) $st->fetchColumn();
        } else {
            $steps[0]['count'] = (int) $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
        }
    }

    $adSql = [];
    foreach (['orders', 'orderst', 'ordersg', 'add_ob_gp', 'add_ob_vidt', 'add_ob_gr'] as $tbl) {
        if (!crg_admin_stats_table_exists($pdo, $tbl)) {
            continue;
        }
        $dateCol = crg_admin_stats_column_exists($pdo, $tbl, 'created_at') ? 'created_at' : null;
        if ($dateCol !== null) {
            $adSql[] = "SELECT DISTINCT iduser AS uid FROM `{$tbl}` WHERE created_at >= " . $pdo->quote($from) . ' AND created_at <= ' . $pdo->quote($to);
        } else {
            $adSql[] = "SELECT DISTINCT iduser AS uid FROM `{$tbl}`";
        }
    }
    if ($adSql !== []) {
        $union = implode(' UNION ', $adSql);
        $st = $pdo->query("SELECT COUNT(*) FROM ({$union}) t WHERE uid IS NOT NULL AND TRIM(uid) != '' AND uid != '0'");
        if ($st) {
            $steps[1]['count'] = (int) $st->fetchColumn();
        }
    }

    foreach (['offer_data', 'offer_dataf'] as $tbl) {
        if (!crg_admin_stats_table_exists($pdo, $tbl)) {
            continue;
        }
        if (crg_admin_stats_column_exists($pdo, $tbl, 'created_at')) {
            $st = $pdo->prepare("SELECT COUNT(*) FROM `{$tbl}` WHERE created_at >= ? AND created_at <= ?");
            $st->execute([$from, $to]);
        } else {
            $st = $pdo->query("SELECT COUNT(*) FROM `{$tbl}`");
        }
        if ($st) {
            $steps[2]['count'] += (int) $st->fetchColumn();
        }
    }

    if (crg_admin_stats_table_exists($pdo, 'ordersglobal')) {
        $st = $pdo->prepare(
            "SELECT COUNT(*) FROM ordersglobal WHERE status = 'выполнен'
             AND end_time >= ? AND end_time <= ?"
        );
        $st->execute([$from, $to]);
        $steps[3]['count'] = (int) $st->fetchColumn();
    }

    if (crg_admin_stats_table_exists($pdo, 'subscription_payment_log')) {
        $st = $pdo->prepare(
            'SELECT COUNT(DISTINCT iduser) FROM subscription_payment_log
             WHERE paid_at >= ? AND paid_at <= ?'
        );
        $st->execute([$from, $to]);
        $steps[4]['count'] = (int) $st->fetchColumn();
    }

    $base = max(1, (int) $steps[0]['count']);
    foreach ($steps as &$step) {
        $step['pct_of_reg'] = round(100 * ((int) $step['count']) / $base, 1);
    }
    unset($step);

    for ($i = 1; $i < count($steps); $i++) {
        $prev = max(1, (int) $steps[$i - 1]['count']);
        $steps[$i]['conversion_from_prev_pct'] = round(100 * ((int) $steps[$i]['count']) / $prev, 1);
    }

    return [
        'period_from' => $from,
        'period_to' => $to,
        'steps' => $steps,
    ];
}

function crg_admin_stats_fmt_int(?int $n): string
{
    if ($n === null) {
        return '—';
    }

    return number_format($n, 0, ',', ' ');
}

function crg_admin_stats_fmt_rub(int|float|null $n): string
{
    if ($n === null) {
        return '—';
    }

    $isInt = is_int($n) || (is_float($n) && $n === floor($n));

    return number_format((float) $n, $isInt ? 0 : 2, ',', ' ') . ' ₽';
}

function crg_admin_stats_fmt_pct(int $part, int $whole): string
{
    if ($whole <= 0) {
        return '—';
    }

    return number_format(100 * $part / $whole, 1, ',', '') . '%';
}
