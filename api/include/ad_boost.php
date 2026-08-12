<?php
declare(strict_types=1);

/** @return array<int, string> */
function crg_boost_supply_table_for_bd(int $bd): array
{
    switch ($bd) {
        case 1:
            return ['table' => 'add_ob_gp', 'label' => 'Грузоперевозки'];
        case 2:
            return ['table' => 'add_ob_vidt', 'label' => 'Спецтехника'];
        case 3:
            return ['table' => 'add_ob_gr', 'label' => 'Грузчики'];
        default:
            return ['table' => '', 'label' => ''];
    }
}

function crg_boost_table_exists(PDO $pdo, string $table): bool
{
    static $cache = [];
    if (isset($cache[$table])) {
        return $cache[$table];
    }
    try {
        $st = $pdo->query('SHOW TABLES LIKE ' . $pdo->quote($table));

        return $cache[$table] = $st->fetch() !== false;
    } catch (Throwable $e) {
        return $cache[$table] = false;
    }
}

/** @return list<array<string, mixed>> */
function crg_boost_active_tariffs(PDO $pdo): array
{
    if (!crg_boost_table_exists($pdo, 'ad_boost_tariffs')) {
        return [
            ['id' => 1, 'code' => '24h', 'title' => 'В топ 24 ч', 'hours' => 24, 'price_rub' => 199],
            ['id' => 2, 'code' => '72h', 'title' => 'В топ 72 ч', 'hours' => 72, 'price_rub' => 399],
        ];
    }
    $st = $pdo->query(
        'SELECT id, code, title, hours, price_rub FROM ad_boost_tariffs
         WHERE is_active = 1 ORDER BY sort_order, id'
    );

    return $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

/** @return array<string, mixed>|null */
function crg_boost_tariff_by_id(PDO $pdo, int $id): ?array
{
    foreach (crg_boost_active_tariffs($pdo) as $row) {
        if ((int) ($row['id'] ?? 0) === $id) {
            return $row;
        }
    }

    return null;
}

/**
 * @param list<array<string, mixed>> $rows
 * @return list<array<string, mixed>>
 */
function crg_boost_enrich_supply_rows(mysqli $conn, array $rows, int $bd): array
{
    if ($rows === [] || $bd <= 0) {
        return $rows;
    }
    $ids = [];
    foreach ($rows as $row) {
        $id = (int) ($row['id'] ?? 0);
        if ($id > 0) {
            $ids[$id] = $id;
        }
    }
    if ($ids === []) {
        return $rows;
    }

    $map = [];
    $in = implode(',', array_map('intval', array_values($ids)));
    $sql = "SELECT ad_id, MAX(boosted_until) AS boosted_until
            FROM ad_boosts
            WHERE bd = ? AND ad_id IN ({$in}) AND boosted_until > NOW()
            GROUP BY ad_id";
    $stmt = $conn->prepare($sql);
    if ($stmt) {
        $stmt->bind_param('i', $bd);
        $stmt->execute();
        $res = $stmt->get_result();
        while ($res && ($r = $res->fetch_assoc())) {
            $map[(int) $r['ad_id']] = (string) $r['boosted_until'];
        }
        $stmt->close();
    }

    foreach ($rows as &$row) {
        $id = (int) ($row['id'] ?? 0);
        $until = $map[$id] ?? null;
        $row['boosted_until'] = $until;
        $row['is_boosted'] = $until !== null;
    }
    unset($row);

    return $rows;
}

function crg_boost_row_is_active(array $row): bool
{
    if (!empty($row['is_boosted'])) {
        return true;
    }
    $until = $row['boosted_until'] ?? null;
    if ($until === null || $until === '') {
        return false;
    }

    return strtotime((string) $until) > time();
}

/**
 * @param array<string, mixed> $params
 * @return array{ok: bool, error?: string, boosted_until?: string}
 */
function crg_boost_apply_payment(PDO $pdo, array $params): array
{
    $userId = (int) ($params['user_id'] ?? 0);
    $bd = (int) ($params['bd'] ?? 0);
    $adId = (int) ($params['ad_id'] ?? 0);
    $tariffId = (int) ($params['tariff_id'] ?? 0);
    $orderId = trim((string) ($params['payment_order_id'] ?? ''));

    if ($userId <= 0 || $bd <= 0 || $adId <= 0 || $tariffId <= 0 || $orderId === '') {
        return ['ok' => false, 'error' => 'Некорректные параметры'];
    }

    $cfg = crg_boost_supply_table_for_bd($bd);
    if ($cfg['table'] === '' || !crg_boost_table_exists($pdo, $cfg['table'])) {
        return ['ok' => false, 'error' => 'Неизвестная категория объявления'];
    }

    $tariff = crg_boost_tariff_by_id($pdo, $tariffId);
    if ($tariff === null) {
        return ['ok' => false, 'error' => 'Тариф не найден'];
    }

    $st = $pdo->prepare("SELECT id FROM `{$cfg['table']}` WHERE id = ? AND iduser = ? LIMIT 1");
    $st->execute([$adId, $userId]);
    if ($st->fetch() === false) {
        return ['ok' => false, 'error' => 'Объявление не найдено'];
    }

    if (crg_boost_table_exists($pdo, 'ad_boosts')) {
        $chk = $pdo->prepare('SELECT id FROM ad_boosts WHERE payment_order_id = ? LIMIT 1');
        $chk->execute([$orderId]);
        if ($chk->fetch() !== false) {
            $cur = $pdo->prepare(
                'SELECT boosted_until FROM ad_boosts WHERE payment_order_id = ? LIMIT 1'
            );
            $cur->execute([$orderId]);
            $row = $cur->fetch(PDO::FETCH_ASSOC);

            return ['ok' => true, 'boosted_until' => (string) ($row['boosted_until'] ?? '')];
        }
    }

    $hours = max(1, (int) ($tariff['hours'] ?? 24));
    $base = new DateTime('now');
    $extend = $pdo->prepare(
        'SELECT boosted_until FROM ad_boosts
         WHERE bd = ? AND ad_id = ? AND boosted_until > NOW()
         ORDER BY boosted_until DESC LIMIT 1'
    );
    $extend->execute([$bd, $adId]);
    $existing = $extend->fetch(PDO::FETCH_ASSOC);
    if ($existing && !empty($existing['boosted_until'])) {
        try {
            $base = new DateTime((string) $existing['boosted_until']);
        } catch (Throwable $e) {
            $base = new DateTime('now');
        }
    }
    $base->modify('+' . $hours . ' hours');
    $until = $base->format('Y-m-d H:i:s');

    $ins = $pdo->prepare(
        'INSERT INTO ad_boosts (bd, ad_id, user_id, tariff_id, boosted_until, price_rub, payment_order_id)
         VALUES (?, ?, ?, ?, ?, ?, ?)'
    );
    $ins->execute([
        $bd,
        $adId,
        $userId,
        $tariffId,
        $until,
        (int) ($tariff['price_rub'] ?? 0),
        $orderId,
    ]);

    return ['ok' => true, 'boosted_until' => $until];
}
