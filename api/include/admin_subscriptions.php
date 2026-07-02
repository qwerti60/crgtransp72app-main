<?php
declare(strict_types=1);

/**
 * Подписка исполнителя — таблица subscriptions (см. check_subscription.php, update_subscription.php).
 *
 * iduser   — users.idusers (исполнитель)
 * date     — дата окончания подписки (активна, если date >= сегодня)
 * payment  — ID платежа (YooKassa / payment-proxy)
 * count    — число успешных оплат / продлений
 *
 * Тариф — subscription_config (days, price_rub, is_active).
 */

function crg_admin_subscriptions_table_exists(PDO $pdo): bool
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $pdo->query('SELECT 1 FROM subscriptions LIMIT 1');

        return $exists = true;
    } catch (Throwable $e) {
        return $exists = false;
    }
}

function crg_admin_subscription_config_table_exists(PDO $pdo): bool
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $pdo->query('SELECT 1 FROM subscription_config LIMIT 1');

        return $exists = true;
    } catch (Throwable $e) {
        return $exists = false;
    }
}

/**
 * Активный тариф для приложения (is_active = 1, последняя запись).
 *
 * @return array{id: int, days: int, price_rub: int, updated_at: string}|null
 */
function crg_admin_subscription_config_row(PDO $pdo): ?array
{
    if (!crg_admin_subscription_config_table_exists($pdo)) {
        return null;
    }

    try {
        $st = $pdo->query(
            'SELECT id, days, price_rub, updated_at
             FROM subscription_config
             WHERE is_active = 1
             ORDER BY id DESC
             LIMIT 1'
        );
        $row = $st->fetch();
        if ($row === false) {
            return null;
        }

        return [
            'id' => (int) ($row['id'] ?? 0),
            'days' => (int) ($row['days'] ?? 30),
            'price_rub' => (int) ($row['price_rub'] ?? 300),
            'updated_at' => (string) ($row['updated_at'] ?? ''),
        ];
    } catch (Throwable $e) {
        return null;
    }
}

/** @return array{days: int, price_rub: int}|null */
function crg_admin_subscription_config(PDO $pdo): ?array
{
    $row = crg_admin_subscription_config_row($pdo);

    return $row === null ? null : [
        'days' => (int) $row['days'],
        'price_rub' => (int) $row['price_rub'],
    ];
}

/** @return true|string */
function crg_admin_subscription_config_save(PDO $pdo, int $days, int $priceRub): bool|string
{
    if (!crg_admin_subscription_config_table_exists($pdo)) {
        return 'Таблица subscription_config не найдена в БД';
    }
    if ($days < 1 || $days > 3650) {
        return 'Срок подписки — от 1 до 3650 дней';
    }
    if ($priceRub < 1 || $priceRub > 9999999) {
        return 'Цена — от 1 до 9 999 999 ₽';
    }

    try {
        $row = crg_admin_subscription_config_row($pdo);
        if ($row !== null && ($row['id'] ?? 0) > 0) {
            $st = $pdo->prepare(
                'UPDATE subscription_config SET days = ?, price_rub = ? WHERE id = ?'
            );
            $st->execute([$days, $priceRub, (int) $row['id']]);

            return true;
        }

        $st = $pdo->prepare(
            'INSERT INTO subscription_config (days, price_rub, is_active) VALUES (?, ?, 1)'
        );
        $st->execute([$days, $priceRub]);

        return true;
    } catch (Throwable $e) {
        return 'Не удалось сохранить тариф';
    }
}

/**
 * @return array<string, mixed>|null
 */
function crg_admin_subscription_for_user(PDO $pdo, int $userId): ?array
{
    if ($userId <= 0 || !crg_admin_subscriptions_table_exists($pdo)) {
        return null;
    }

    try {
        $st = $pdo->prepare(
            'SELECT id, iduser, date, payment, count
             FROM subscriptions
             WHERE iduser = ?
             ORDER BY id DESC
             LIMIT 1'
        );
        $st->execute([$userId]);
        $row = $st->fetch();

        return $row === false ? null : $row;
    } catch (Throwable $e) {
        return null;
    }
}

/** @return 'active'|'expired'|'none' */
function crg_admin_subscription_status(?array $row): string
{
    if ($row === null || empty($row['date'])) {
        return 'none';
    }

    $endDate = (string) $row['date'];

    return $endDate >= date('Y-m-d') ? 'active' : 'expired';
}

function crg_admin_subscription_status_label(string $status): string
{
    return match ($status) {
        'active' => 'Активна',
        'expired' => 'Истекла',
        default => 'Не оформлена',
    };
}

function crg_admin_subscription_days_left(?array $row): ?int
{
    if ($row === null || empty($row['date'])) {
        return null;
    }
    try {
        $end = new DateTimeImmutable((string) $row['date']);
        $today = new DateTimeImmutable('today');
        if ($end < $today) {
            return 0;
        }

        return (int) $today->diff($end)->days;
    } catch (Throwable $e) {
        return null;
    }
}

/**
 * @param list<int> $userIds
 * @return array<int, array<string, mixed>>
 */
function crg_admin_subscription_map_for_users(PDO $pdo, array $userIds): array
{
    $userIds = array_values(array_unique(array_filter(array_map('intval', $userIds), static fn (int $id): bool => $id > 0)));
    if ($userIds === [] || !crg_admin_subscriptions_table_exists($pdo)) {
        return [];
    }

    $placeholders = implode(',', array_fill(0, count($userIds), '?'));
    try {
        $st = $pdo->prepare(
            "SELECT id, iduser, date, payment, count
             FROM subscriptions
             WHERE iduser IN ({$placeholders})
             ORDER BY iduser, id DESC"
        );
        $st->execute($userIds);
        $map = [];
        foreach ($st->fetchAll() as $row) {
            $uid = (int) ($row['iduser'] ?? 0);
            if ($uid > 0 && !isset($map[$uid])) {
                $map[$uid] = $row;
            }
        }

        return $map;
    } catch (Throwable $e) {
        return [];
    }
}

function crg_admin_render_subscription_badge(?array $row): void
{
    $status = crg_admin_subscription_status($row);
    $cls = match ($status) {
        'active' => 'badge-ok',
        'expired' => 'badge-pending',
        default => 'badge-muted',
    };
    echo '<span class="badge ' . $cls . '">' . tp_admin_web_h(crg_admin_subscription_status_label($status)) . '</span>';
    if ($status === 'active' && $row !== null && !empty($row['date'])) {
        echo '<div class="meta">до ' . tp_admin_web_h((string) $row['date']) . '</div>';
    }
}

function crg_admin_render_performer_subscription(PDO $pdo, int $userId): void
{
    if (!crg_admin_subscriptions_table_exists($pdo)) {
        echo '<div class="card"><p class="meta"><strong>Подписка исполнителя</strong></p>';
        echo '<p class="meta">Таблица subscriptions не найдена в БД.</p></div>';

        return;
    }

    $sub = crg_admin_subscription_for_user($pdo, $userId);
    $status = crg_admin_subscription_status($sub);
    $config = crg_admin_subscription_config($pdo);

    echo '<div class="card">';
    echo '<p class="meta"><strong>Подписка исполнителя</strong></p>';
    echo '<p>';
    crg_admin_render_subscription_badge($sub);
    echo '</p>';

    if ($sub === null) {
        echo '<p class="meta">Исполнитель ещё не оформлял подписку. Без активной подписки приложение ограничивает доступ к функциям исполнителя (см. check_subscription.php).</p>';
    } else {
        echo '<table class="data"><tbody>';
        echo '<tr><th>Действует до</th><td>' . tp_admin_web_h((string) ($sub['date'] ?? '')) . '</td></tr>';
        $daysLeft = crg_admin_subscription_days_left($sub);
        if ($status === 'active' && $daysLeft !== null) {
            echo '<tr><th>Осталось дней</th><td>' . (int) $daysLeft . '</td></tr>';
        }
        $payment = trim((string) ($sub['payment'] ?? ''));
        echo '<tr><th>ID платежа</th><td>' . ($payment !== '' ? tp_admin_web_h($payment) : '—') . '</td></tr>';
        echo '<tr><th>Число оплат</th><td class="num">' . (int) ($sub['count'] ?? 0) . '</td></tr>';
        echo '</tbody></table>';
    }

    if ($config !== null) {
        echo '<p class="meta">Текущий тариф в приложении: '
            . (int) $config['days'] . ' дн., '
            . (int) $config['price_rub'] . ' ₽. '
            . '<a href="settings.php">Изменить в настройках</a>.</p>';
    } elseif (!crg_admin_subscription_config_table_exists($pdo)) {
        echo '<p class="meta">Таблица subscription_config не найдена — тариф задаётся в коде приложения (30 дн., 300 ₽).</p>';
    }

    echo '</div>';
}
