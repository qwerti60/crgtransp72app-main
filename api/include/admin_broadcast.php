<?php
declare(strict_types=1);

/** @return array<string, string> */
function crg_admin_broadcast_audience_labels(): array
{
    return [
        'all' => 'Все пользователи',
        'city' => 'По городам',
        'subscription_ending_3' => 'Подписка: осталось 3 дня',
        'subscription_expired' => 'Подписка истекла',
        'role' => 'По роли',
        'selected' => 'Выбранные пользователи (ID)',
    ];
}

/** @return list<string> */
function crg_admin_broadcast_city_options(PDO $pdo): array
{
    try {
        $st = $pdo->query('SELECT name FROM cities ORDER BY name ASC');
        $rows = $st->fetchAll();
        if ($rows !== []) {
            return array_values(array_filter(array_map(
                static fn (array $r): string => trim((string) ($r['name'] ?? '')),
                $rows
            )));
        }
    } catch (Throwable $e) {
        // fallback
    }

    try {
        $st = $pdo->query(
            'SELECT DISTINCT city FROM users WHERE city IS NOT NULL AND TRIM(city) != \'\' ORDER BY city ASC'
        );

        return array_values(array_filter(array_map(
            static fn (array $r): string => trim((string) ($r['city'] ?? '')),
            $st->fetchAll()
        )));
    } catch (Throwable $e) {
        return [];
    }
}

/**
 * @param array<string, mixed> $input
 * @return array{audience: string, cities: list<string>, roles: list<int>, user_ids: list<int>, subject: string, message: string, send_mail: bool, send_push: bool}
 */
function crg_admin_broadcast_parse_form(array $input): array
{
    $audience = trim((string) ($input['audience'] ?? 'all'));
    if (!array_key_exists($audience, crg_admin_broadcast_audience_labels())) {
        $audience = 'all';
    }

    $cities = [];
    if (isset($input['cities']) && is_array($input['cities'])) {
        foreach ($input['cities'] as $c) {
            $c = trim((string) $c);
            if ($c !== '') {
                $cities[] = $c;
            }
        }
    }

    $roles = [];
    if (isset($input['roles']) && is_array($input['roles'])) {
        foreach ($input['roles'] as $r) {
            $r = (int) $r;
            if ($r >= 1 && $r <= 4) {
                $roles[] = $r;
            }
        }
    }

    $userIds = [];
    $rawIds = trim((string) ($input['user_ids'] ?? ''));
    if ($rawIds !== '') {
        foreach (preg_split('/[\s,;]+/', $rawIds) ?: [] as $part) {
            $id = (int) $part;
            if ($id > 0) {
                $userIds[$id] = $id;
            }
        }
    }

    return [
        'audience' => $audience,
        'cities' => array_values(array_unique($cities)),
        'roles' => array_values(array_unique($roles)),
        'user_ids' => array_values($userIds),
        'subject' => trim((string) ($input['subject'] ?? '')),
        'message' => trim((string) ($input['message'] ?? '')),
        'send_mail' => !empty($input['send_mail']),
        'send_push' => !empty($input['send_push']),
    ];
}

/** @return string|null */
function crg_admin_broadcast_validate_form(array $form): ?string
{
    if (!$form['send_mail'] && !$form['send_push']) {
        return 'Выберите канал: e-mail и/или push';
    }
    if ($form['send_mail'] && $form['subject'] === '') {
        return 'Укажите тему письма';
    }
    if ($form['send_push'] && $form['subject'] === '') {
        return 'Укажите заголовок push (поле «Тема»)';
    }
    if (mb_strlen($form['message']) < 5) {
        return 'Текст сообщения — не менее 5 символов';
    }

    return match ($form['audience']) {
        'city' => $form['cities'] === [] ? 'Выберите хотя бы один город' : null,
        'role' => $form['roles'] === [] ? 'Выберите хотя бы одну роль' : null,
        'selected' => $form['user_ids'] === [] ? 'Укажите ID пользователей' : null,
        default => null,
    };
}

function crg_admin_broadcast_subscriptions_exists(PDO $pdo): bool
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

function crg_admin_broadcast_users_has_fcm(PDO $pdo): bool
{
    static $has = null;
    if ($has !== null) {
        return $has;
    }
    try {
        $st = $pdo->query("SHOW COLUMNS FROM users LIKE 'fcm_token'");

        return $has = $st->fetch() !== false;
    } catch (Throwable $e) {
        return $has = false;
    }
}

function crg_admin_broadcast_user_select(PDO $pdo): string
{
    $fcm = crg_admin_broadcast_users_has_fcm($pdo) ? 'u.fcm_token' : 'NULL AS fcm_token';

    return 'u.idusers, u.email, ' . $fcm . ', u.firstName, u.lastName, u.middleName, u.namefirm, u.city, u.rollNum';
}

/**
 * @param list<array<string, mixed>> $rows
 * @return list<array<string, mixed>>
 */
function crg_admin_broadcast_dedupe_users(array $rows): array
{
    $out = [];
    foreach ($rows as $row) {
        $id = (int) ($row['idusers'] ?? 0);
        if ($id > 0) {
            $out[$id] = $row;
        }
    }

    return array_values($out);
}

/**
 * @param array<string, mixed> $form
 * @return list<array<string, mixed>>
 */
function crg_admin_broadcast_recipients(PDO $pdo, array $form): array
{
    $audience = $form['audience'];
    $hasSubs = crg_admin_broadcast_subscriptions_exists($pdo);
    $select = crg_admin_broadcast_user_select($pdo);

    try {
        if ($audience === 'all') {
            $st = $pdo->query("SELECT {$select} FROM users u ORDER BY u.idusers ASC");

            return crg_admin_broadcast_dedupe_users($st->fetchAll());
        }

        if ($audience === 'city') {
            $cities = $form['cities'];
            if ($cities === []) {
                return [];
            }
            $ph = implode(',', array_fill(0, count($cities), '?'));
            $st = $pdo->prepare("SELECT {$select} FROM users u WHERE u.city IN ({$ph}) ORDER BY u.idusers ASC");
            $st->execute($cities);

            return crg_admin_broadcast_dedupe_users($st->fetchAll());
        }

        if ($audience === 'role') {
            $roles = $form['roles'];
            if ($roles === []) {
                return [];
            }
            $ph = implode(',', array_fill(0, count($roles), '?'));
            $st = $pdo->prepare("SELECT {$select} FROM users u WHERE u.rollNum IN ({$ph}) ORDER BY u.idusers ASC");
            $st->execute($roles);

            return crg_admin_broadcast_dedupe_users($st->fetchAll());
        }

        if ($audience === 'selected') {
            $ids = $form['user_ids'];
            if ($ids === []) {
                return [];
            }
            $ph = implode(',', array_fill(0, count($ids), '?'));
            $st = $pdo->prepare("SELECT {$select} FROM users u WHERE u.idusers IN ({$ph}) ORDER BY u.idusers ASC");
            $st->execute($ids);

            return crg_admin_broadcast_dedupe_users($st->fetchAll());
        }

        if (!$hasSubs) {
            return [];
        }

        if ($audience === 'subscription_ending_3') {
            $st = $pdo->query(
                "SELECT {$select}
                 FROM users u
                 INNER JOIN subscriptions s ON s.iduser = u.idusers
                 WHERE s.date = DATE_ADD(CURDATE(), INTERVAL 3 DAY)
                 ORDER BY u.idusers ASC"
            );

            return crg_admin_broadcast_dedupe_users($st->fetchAll());
        }

        if ($audience === 'subscription_expired') {
            $st = $pdo->query(
                "SELECT {$select}
                 FROM users u
                 INNER JOIN subscriptions s ON s.iduser = u.idusers
                 WHERE s.date < CURDATE()
                 ORDER BY u.idusers ASC"
            );

            return crg_admin_broadcast_dedupe_users($st->fetchAll());
        }
    } catch (Throwable $e) {
        return [];
    }

    return [];
}

/**
 * @param list<array<string, mixed>> $recipients
 * @return array{total: int, mail_ok: int, mail_skip: int, mail_fail: int, push_ok: int, push_skip: int, push_fail: int, errors: list<string>}
 */
function crg_admin_broadcast_send(PDO $pdo, array $recipients, array $form): array
{
    tp_admin_web_require_include('admin_mail.php');
    tp_admin_web_require_include('fcm_push.php');
    tp_admin_web_require_include('admin_users.php');

    $stats = [
        'total' => count($recipients),
        'mail_ok' => 0,
        'mail_skip' => 0,
        'mail_fail' => 0,
        'push_ok' => 0,
        'push_skip' => 0,
        'push_fail' => 0,
        'errors' => [],
    ];

    $subject = $form['subject'];
    $message = $form['message'];
    $pushBody = crg_admin_notify_excerpt($message, 240);
    $sendMail = $form['send_mail'];
    $sendPush = $form['send_push'];

    if ($sendPush) {
        $oauth = crg_fcm_acquire_access_token();
        if ($oauth === false) {
            $err = crg_fcm_last_error() ?? 'Не удалось авторизоваться в Firebase';
            $stats['errors'][] = 'FCM: ' . $err;
        }
    }

    foreach ($recipients as $user) {
        $uid = (int) ($user['idusers'] ?? 0);
        $email = trim((string) ($user['email'] ?? ''));
        $token = trim((string) ($user['fcm_token'] ?? ''));

        if ($sendMail) {
            if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                ++$stats['mail_skip'];
            } else {
                $name = crg_admin_user_display_name($user);
                $body = "Здравствуйте";
                if ($name !== '' && $name !== ('#' . $uid)) {
                    $body .= ', ' . $name;
                }
                $body .= "!\n\n" . $message . "\n\n—\nCRG Transp72\n";
                $res = crg_admin_send_plain_mail($email, $subject, $body);
                if ($res === true) {
                    ++$stats['mail_ok'];
                } else {
                    ++$stats['mail_fail'];
                    if (count($stats['errors']) < 5 && is_string($res)) {
                        $stats['errors'][] = "#{$uid} e-mail: {$res}";
                    }
                }
            }
        }

        if ($sendPush) {
            if ($token === '') {
                ++$stats['push_skip'];
            } else {
                $tokenCheck = crg_fcm_validate_device_token($token);
                if ($tokenCheck !== true) {
                    ++$stats['push_fail'];
                    crg_fcm_clear_user_token($pdo, $uid);
                    if (count($stats['errors']) < 5) {
                        $stats['errors'][] = "#{$uid} push: {$tokenCheck}";
                    }
                } else {
                $res = crg_fcm_send($token, $subject, crg_fcm_push_body_with_stamp($pushBody), true, crg_fcm_delivery_tag());
                if ($res === true) {
                    ++$stats['push_ok'];
                } else {
                    ++$stats['push_fail'];
                    if (count($stats['errors']) < 5 && is_string($res)) {
                        $stats['errors'][] = "#{$uid} push: {$res}";
                    }
                    if (is_string($res) && crg_fcm_is_invalid_token_error($res)) {
                        crg_fcm_clear_user_token($pdo, $uid);
                    }
                }
                }
            }
        }
    }

    return $stats;
}

function crg_admin_broadcast_stats_summary(array $stats, bool $sendMail, bool $sendPush): string
{
    $parts = ['Получателей в выборке: ' . (int) ($stats['total'] ?? 0)];
    if ($sendMail) {
        $parts[] = 'e-mail: ' . (int) ($stats['mail_ok'] ?? 0) . ' отправлено'
            . ', пропущено ' . (int) ($stats['mail_skip'] ?? 0)
            . ', ошибок ' . (int) ($stats['mail_fail'] ?? 0);
    }
    if ($sendPush) {
        $parts[] = 'push: ' . (int) ($stats['push_ok'] ?? 0) . ' отправлено'
            . ', пропущено ' . (int) ($stats['push_skip'] ?? 0)
            . ' (нет FCM-токена в БД)'
            . ', ошибок ' . (int) ($stats['push_fail'] ?? 0);
    }

    return implode('. ', $parts) . '.';
}

/** @param list<array<string, mixed>> $recipients */
function crg_admin_broadcast_push_ready_count(array $recipients): int
{
    $count = 0;
    foreach ($recipients as $user) {
        if (trim((string) ($user['fcm_token'] ?? '')) !== '') {
            ++$count;
        }
    }

    return $count;
}
