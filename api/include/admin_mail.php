<?php
declare(strict_types=1);

require_once __DIR__ . '/site_config.php';

function crg_admin_mail_from(): string
{
    require_once __DIR__ . '/mail_config.php';

    return crg_mail_from_address();
}

function crg_admin_mail_encode_subject(string $subject): string
{
    if (function_exists('mb_encode_mimeheader')) {
        return mb_encode_mimeheader($subject, 'UTF-8', 'B', "\r\n");
    }

    return '=?UTF-8?B?' . base64_encode($subject) . '?=';
}

/** @return true|string true on success, error message on failure */
function crg_admin_send_plain_mail(string $to, string $subject, string $body): bool|string
{
    require_once __DIR__ . '/mail_config.php';

    $to = trim($to);
    if ($to === '' || !filter_var($to, FILTER_VALIDATE_EMAIL)) {
        return 'Некорректный e-mail получателя';
    }

    $from = crg_mail_from_address();
    $settings = crg_mail_settings();

    if ($settings['smtp'] !== null) {
        $smtpRes = crg_mail_smtp_send($settings['smtp'], $from, $to, $subject, $body);
        if ($smtpRes === true) {
            return true;
        }

        $hostingRes = crg_mail_hosting_send($from, $to, $subject, $body);
        if ($hostingRes === true) {
            return true;
        }

        return is_string($smtpRes) ? $smtpRes : 'Не удалось отправить письмо';
    }

    if (!crg_mail_local_exists()) {
        return 'Почта не настроена: создайте api/mail.local.php (см. mail.local.example.php)';
    }

    return crg_mail_hosting_send($from, $to, $subject, $body);
}

function crg_mail_log_delivery(string $type, string $to, bool|string $result): void
{
    $dir = dirname(__DIR__) . '/logs';
    if (!is_dir($dir)) {
        @mkdir($dir, 0755, true);
    }
    $line = date('Y-m-d H:i:s') . "\t{$type}\t{$to}\t"
        . ($result === true ? 'ok' : (string) $result) . "\n";
    @file_put_contents($dir . '/mail_delivery.log', $line, FILE_APPEND | LOCK_EX);
}

/**
 * Письмо с кодом (тема как в админке: CRG Transp72: ...).
 *
 * @return true|string
 */
function crg_admin_send_code_mail(
    string $to,
    string $subjectSuffix,
    string $code,
    string $validMinutesText = '15 минут'
): bool|string {
    $subject = 'CRG Transp72: ' . $subjectSuffix;
    $body = "Здравствуйте!\n\n";
    $body .= "Ваш код: {$code}\n";
    $body .= "Код действует {$validMinutesText}.\n\n";
    $body .= "Если вы не запрашивали это действие — проигнорируйте письмо.\n\n";
    $body .= "—\n";
    $body .= "Грузоперевозки72\n";

    $result = crg_admin_send_plain_mail($to, $subject, $body);
    crg_mail_log_delivery($subjectSuffix, $to, $result);

    return $result;
}

/**
 * @param array<string, mixed> $cfg
 * @return true|string
 */
function crg_admin_send_performer_ad_rejection_mail(
    PDO $pdo,
    array $cfg,
    int $adId,
    int $userId,
    string $adminMessage
): bool|string {
    tp_admin_web_require_include('admin_users.php');

    $user = crg_admin_user_get($pdo, $userId);
    if ($user === null) {
        return 'Пользователь не найден';
    }

    $email = trim((string) ($user['email'] ?? ''));
    if ($email === '') {
        return 'У пользователя не указан e-mail';
    }

    $name = crg_admin_user_display_name($user);
    $category = (string) ($cfg['label'] ?? 'объявление');
    $subject = 'CRG Transp72: объявление не опубликовано — требуются правки';

    $body = "Здравствуйте";
    if ($name !== '' && $name !== ('#' . $userId)) {
        $body .= ', ' . $name;
    }
    $body .= "!\n\n";
    $body .= "Ваше объявление №{$adId} ({$category}) не прошло модерацию и пока не опубликовано в приложении.\n\n";
    $body .= "Что нужно исправить:\n";
    $body .= $adminMessage . "\n\n";
    $body .= "Внесите изменения в приложении и дождитесь повторной проверки.\n\n";
    $body .= "—\n";
    $body .= "CRG Transp72\n";

    return crg_admin_send_plain_mail($email, $subject, $body);
}

/**
 * @param array<string, mixed> $cfg
 * @return true|string
 */
function crg_admin_send_performer_ad_approval_mail(
    PDO $pdo,
    array $cfg,
    int $adId,
    int $userId
): bool|string {
    tp_admin_web_require_include('admin_users.php');

    $user = crg_admin_user_get($pdo, $userId);
    if ($user === null) {
        return 'Пользователь не найден';
    }

    $email = trim((string) ($user['email'] ?? ''));
    if ($email === '') {
        return 'У пользователя не указан e-mail';
    }

    $name = crg_admin_user_display_name($user);
    $category = (string) ($cfg['label'] ?? 'объявление');
    $subject = 'CRG Transp72: объявление опубликовано';

    $body = "Здравствуйте";
    if ($name !== '' && $name !== ('#' . $userId)) {
        $body .= ', ' . $name;
    }
    $body .= "!\n\n";
    $body .= "Ваше объявление №{$adId} ({$category}) прошло модерацию и опубликовано в приложении.\n";
    $body .= "Заказчики уже могут видеть его в списке.\n\n";
    $body .= "—\n";
    $body .= "CRG Transp72\n";

    return crg_admin_send_plain_mail($email, $subject, $body);
}

/**
 * @param array<string, mixed> $cfg
 * @return array{ok: bool, error: string, mail: bool|null, push: bool|null}
 */
function crg_admin_notify_user_mail_and_push(
    PDO $pdo,
    int $userId,
    string $pushTitle,
    string $pushBody,
    ?callable $sendMail
): array {
    tp_admin_web_require_include('admin_users.php');
    tp_admin_web_require_include('fcm_push.php');

    $user = crg_admin_user_get($pdo, $userId);
    if ($user === null) {
        return ['ok' => false, 'error' => 'Пользователь не найден', 'mail' => null, 'push' => null];
    }

    $email = trim((string) ($user['email'] ?? ''));
    $hasEmail = $email !== '' && filter_var($email, FILTER_VALIDATE_EMAIL);
    $tokenData = crg_fcm_user_device_token($pdo, $userId);
    $hasPush = $tokenData !== null && ($tokenData['token'] ?? '') !== '';
    $tokenError = is_array($tokenData) && ($tokenData['token'] ?? '') === '' && ($tokenData['error'] ?? '') !== ''
        ? (string) $tokenData['error']
        : '';

    if (!$hasEmail && !$hasPush) {
        $err = $tokenError !== '' ? $tokenError : 'Нет e-mail и push-токена — уведомить исполнителя нельзя';

        return [
            'ok' => false,
            'error' => $err,
            'mail' => null,
            'push' => null,
        ];
    }

    $mailOk = null;
    $pushOk = null;
    $errors = [];

    if ($hasPush) {
        $oauth = crg_fcm_acquire_access_token();
        if ($oauth === false) {
            $errors[] = 'FCM: ' . (crg_fcm_last_error() ?? 'OAuth Firebase');
        }
    }

    if ($hasEmail && $sendMail !== null) {
        $mailRes = $sendMail();
        $mailOk = $mailRes === true;
        if (!$mailOk && is_string($mailRes)) {
            $errors[] = $mailRes;
        }
    }

    if ($hasPush) {
        $pushRes = crg_fcm_send_to_user($pdo, $userId, $pushTitle, $pushBody);
        if ($pushRes === null) {
            $pushOk = null;
        } elseif ($pushRes === true) {
            $pushOk = true;
        } else {
            $pushOk = false;
            $errors[] = is_string($pushRes) ? $pushRes : 'Не удалось отправить push';
        }
    } else {
        $pushOk = null;
    }

    $anySent = ($mailOk === true) || ($pushOk === true);
    if (!$anySent) {
        return [
            'ok' => false,
            'error' => $errors !== [] ? implode('; ', $errors) : 'Не удалось отправить уведомления',
            'mail' => $mailOk,
            'push' => $pushOk,
        ];
    }

    return ['ok' => true, 'error' => '', 'mail' => $mailOk, 'push' => $pushOk];
}

/**
 * Одобрение объявления: e-mail + push (как рассылка / отклонение).
 *
 * @param array<string, mixed> $cfg
 * @return array{ok: bool, error: string, mail: bool|null, push: bool|null}
 */
function crg_admin_approve_performer_ad_notify(
    PDO $pdo,
    array $cfg,
    int $adId,
    int $userId
): array {
    tp_admin_web_require_include('admin_ads.php');

    crg_admin_performer_ad_set_flag($pdo, $cfg, $adId, 1);

    $category = (string) ($cfg['label'] ?? 'объявление');
    $pushTitle = 'Объявление опубликовано';
    $pushBody = '№' . $adId . ' (' . $category . ') прошло модерацию и доступно заказчикам.';

    return crg_admin_notify_user_mail_and_push(
        $pdo,
        $userId,
        $pushTitle,
        $pushBody,
        static function () use ($pdo, $cfg, $adId, $userId): bool|string {
            return crg_admin_send_performer_ad_approval_mail($pdo, $cfg, $adId, $userId);
        }
    );
}

/**
 * Отклонение объявления: e-mail + push (как send_notification.php / users.fcm_token).
 *
 * @param array<string, mixed> $cfg
 * @return array{ok: bool, error: string, mail: bool|null, push: bool|null}
 */
function crg_admin_reject_performer_ad_notify(
    PDO $pdo,
    array $cfg,
    int $adId,
    int $userId,
    string $adminMessage
): array {
    tp_admin_web_require_include('admin_ads.php');
    tp_admin_web_require_include('fcm_push.php');

    crg_admin_performer_ad_set_flag($pdo, $cfg, $adId, 0);

    $category = (string) ($cfg['label'] ?? 'объявление');
    $pushTitle = 'Объявление не опубликовано';
    $pushBody = '№' . $adId . ' (' . $category . '): ' . crg_admin_notify_excerpt($adminMessage);

    return crg_admin_notify_user_mail_and_push(
        $pdo,
        $userId,
        $pushTitle,
        $pushBody,
        static function () use ($pdo, $cfg, $adId, $userId, $adminMessage): bool|string {
            return crg_admin_send_performer_ad_rejection_mail($pdo, $cfg, $adId, $userId, $adminMessage);
        }
    );
}

function crg_admin_ad_notify_flash_message(array $result, string $prefix): string
{
    if (!($result['ok'] ?? false)) {
        return (string) ($result['error'] ?? 'Ошибка отправки');
    }

    $parts = [$prefix];
    if ($result['mail'] === true) {
        $parts[] = 'Письмо отправлено';
    } elseif ($result['mail'] === false) {
        $parts[] = 'Письмо не отправлено';
    }
    if ($result['push'] === true) {
        $parts[] = 'Push принят Firebase — проверьте телефон (приложение свёрнуто или в фоне, уведомления разрешены)';
    } elseif ($result['push'] === false) {
        $parts[] = 'Push не отправлен';
    } elseif ($result['push'] === null) {
        $parts[] = 'Push пропущен: нет FCM-токена — исполнитель должен войти в приложение заново';
    }

    return implode('. ', $parts) . '.';
}

function crg_admin_reject_notify_flash_message(array $result): string
{
    return crg_admin_ad_notify_flash_message($result, 'Объявление остаётся на проверке.');
}

function crg_admin_approve_notify_flash_message(array $result): string
{
    return crg_admin_ad_notify_flash_message($result, 'Объявление опубликовано.');
}

function crg_admin_render_performer_ad_reject_form(): void
{
    ?>
    <p class="meta"><strong>Отклонить с пояснением</strong></p>
    <form method="post" action="" onsubmit="return confirm('Отправить исполнителю письмо и push с замечаниями?');">
        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
        <input type="hidden" name="reject_ad" value="1">
        <label class="b" for="reject_message">Что нужно исправить</label>
        <textarea class="in" name="reject_message" id="reject_message" rows="5" required minlength="5" maxlength="4000" placeholder="Например: замените фото документов, укажите актуальную грузоподъёмность…"><?= tp_admin_web_h((string) ($_POST['reject_message'] ?? '')) ?></textarea>
        <p class="form-actions" style="margin-top:0.75rem">
            <button type="submit" class="btn danger">Отклонить и уведомить</button>
        </p>
    </form>
    <?php
}
