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
 * @return array<string, mixed>
 */
function crg_admin_stats_dashboard(PDO $pdo): array
{
    tp_admin_web_require_include('admin_users.php');
    tp_admin_web_require_include('admin_ads.php');
    tp_admin_web_require_include('admin_subscriptions.php');

    $out = [
        'generated_at' => date('Y-m-d H:i:s'),
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

    return $out;
}

function crg_admin_stats_fmt_int(?int $n): string
{
    if ($n === null) {
        return '—';
    }

    return number_format($n, 0, ',', ' ');
}

function crg_admin_stats_fmt_pct(int $part, int $whole): string
{
    if ($whole <= 0) {
        return '—';
    }

    return number_format(100 * $part / $whole, 1, ',', '') . '%';
}
