<?php
declare(strict_types=1);

/** Минимальная длина нового пароля админки. */
const TP_ADMIN_PASSWORD_MIN_LEN = 10;

function crg_admin_password_otp_ttl_seconds(): int
{
    $ttl = getenv('CRG_ADMIN_PASSWORD_OTP_TTL');
    if ($ttl !== false && $ttl !== '') {
        $n = (int) $ttl;
        if ($n >= 120 && $n <= 3600) {
            return $n;
        }
    }

    return 900;
}

/**
 * E-mail для кода сброса: admin_accounts.email или CRG_ADMIN_PASSWORD_RESET_FALLBACK.
 */
function tp_admin_password_reset_recipient(PDO $pdo, string $login): ?string
{
    $login = trim($login);
    if ($login === '') {
        return null;
    }

    try {
        $st = $pdo->prepare('SELECT email FROM admin_accounts WHERE login = ? LIMIT 1');
        $st->execute([$login]);
        $row = $st->fetch();
        if ($row !== false) {
            $em = trim((string) ($row['email'] ?? ''));
            if ($em !== '' && filter_var($em, FILTER_VALIDATE_EMAIL)) {
                return $em;
            }
        }
    } catch (Throwable $e) {
        return null;
    }

    $fb = getenv('CRG_ADMIN_PASSWORD_RESET_FALLBACK');
    if (is_string($fb) && $fb !== '' && filter_var($fb, FILTER_VALIDATE_EMAIL)) {
        return $fb;
    }

    return null;
}

/** @return true|string */
function tp_admin_password_validate_new(string $newPassword, string $newPassword2): bool|string
{
    if ($newPassword !== $newPassword2) {
        return 'Новый пароль и подтверждение не совпадают';
    }
    if (strlen($newPassword) < TP_ADMIN_PASSWORD_MIN_LEN) {
        return 'Новый пароль не короче ' . TP_ADMIN_PASSWORD_MIN_LEN . ' символов';
    }

    return true;
}

/** @return true|string */
function crg_admin_account_update_email(PDO $pdo, int $adminId, string $email): bool|string
{
    if ($adminId <= 0) {
        return 'Учётная запись не найдена';
    }

    $email = trim($email);
    if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        return 'Укажите корректный e-mail';
    }

    try {
        $st = $pdo->prepare('UPDATE admin_accounts SET email = ? WHERE id = ?');
        $st->execute([$email, $adminId]);

        return true;
    } catch (Throwable $e) {
        return 'Не удалось сохранить e-mail';
    }
}

/**
 * @return array{ok: true, message: string}|array{ok: false, message: string}
 */
function tp_admin_password_request_reset_otp(PDO $pdo, string $login): array
{
    $login = trim($login);
    $genericOk = [
        'ok' => true,
        'message' => 'Если учётная запись найдена и для неё задан e-mail, на почту отправлен код. Проверьте папку «Спам».',
    ];
    if ($login === '') {
        return $genericOk;
    }

    try {
        $st = $pdo->prepare('SELECT id FROM admin_accounts WHERE login = ? LIMIT 1');
        $st->execute([$login]);
        if ($st->fetch() === false) {
            return $genericOk;
        }
    } catch (Throwable $e) {
        return ['ok' => false, 'message' => 'Таблица admin_accounts не найдена'];
    }

    $to = tp_admin_password_reset_recipient($pdo, $login);
    if ($to === null) {
        return $genericOk;
    }

    $ttl = crg_admin_password_otp_ttl_seconds();
    $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

    try {
        $pdo->prepare('DELETE FROM admin_password_reset_otp WHERE login = ?')->execute([$login]);
        $ins = $pdo->prepare(
            'INSERT INTO admin_password_reset_otp (login, code, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))'
        );
        $ins->execute([$login, $code, $ttl]);
    } catch (Throwable $e) {
        return ['ok' => false, 'message' => 'Таблица admin_password_reset_otp не найдена. Выполните sql/migrate_admin_password_reset.sql'];
    }

    tp_admin_web_require_include('admin_mail.php');

    $body = "Код для сброса пароля веб-админки CRG Transp72: {$code}\n\n"
        . "Срок действия кода: " . (int) ($ttl / 60) . " мин.\n"
        . "Если вы не запрашивали сброс, проигнорируйте письмо.\n"
        . 'Логин: ' . $login . "\n";

    $send = crg_admin_send_plain_mail($to, 'Код сброса пароля админки CRG Transp72', $body);
    if ($send !== true) {
        error_log('admin reset mail: ' . $send);

        return ['ok' => false, 'message' => 'Не удалось отправить письмо: ' . $send];
    }

    return $genericOk;
}

/** @return true|string */
function tp_admin_password_complete_reset(
    PDO $pdo,
    string $login,
    string $code,
    string $newPassword,
    string $newPassword2
): bool|string {
    $v = tp_admin_password_validate_new($newPassword, $newPassword2);
    if ($v !== true) {
        return $v;
    }

    $login = trim($login);
    $code = preg_replace('/\D/', '', $code) ?? '';
    if ($login === '' || strlen($code) !== 6) {
        return 'Укажите логин и 6-значный код из письма';
    }

    try {
        $st = $pdo->prepare(
            'SELECT id FROM admin_password_reset_otp
             WHERE login = ? AND code = ? AND expires_at > NOW()
             ORDER BY id DESC LIMIT 1'
        );
        $st->execute([$login, $code]);
        if ($st->fetch() === false) {
            return 'Код неверен или истёк. Запросите новый.';
        }

        $st = $pdo->prepare('SELECT id FROM admin_accounts WHERE login = ? LIMIT 1');
        $st->execute([$login]);
        $acc = $st->fetch();
        if ($acc === false) {
            return 'Учётная запись не найдена';
        }

        $id = (int) $acc['id'];
        $hash = password_hash($newPassword, PASSWORD_DEFAULT);
        $pdo->prepare(
            'UPDATE admin_accounts SET password_hash = ?, token = NULL, token_updated_at = NULL WHERE id = ?'
        )->execute([$hash, $id]);
        $pdo->prepare('DELETE FROM admin_password_reset_otp WHERE login = ?')->execute([$login]);
    } catch (Throwable $e) {
        return 'Не удалось сменить пароль';
    }

    return true;
}

/** @return true|string */
function tp_admin_password_change_with_old(
    PDO $pdo,
    int $adminId,
    string $oldPassword,
    string $newPassword,
    string $newPassword2
): bool|string {
    $v = tp_admin_password_validate_new($newPassword, $newPassword2);
    if ($v !== true) {
        return $v;
    }

    try {
        $st = $pdo->prepare('SELECT password_hash FROM admin_accounts WHERE id = ? LIMIT 1');
        $st->execute([$adminId]);
        $row = $st->fetch();
        if ($row === false) {
            return 'Учётная запись не найдена';
        }
        if (!password_verify($oldPassword, (string) $row['password_hash'])) {
            return 'Неверный текущий пароль';
        }

        $hash = password_hash($newPassword, PASSWORD_DEFAULT);
        $pdo->prepare(
            'UPDATE admin_accounts SET password_hash = ?, token = NULL, token_updated_at = NULL WHERE id = ?'
        )->execute([$hash, $adminId]);
    } catch (Throwable $e) {
        return 'Не удалось сменить пароль';
    }

    return true;
}

/** @return true|string */
function tp_admin_password_reset_logged_in_with_code(
    PDO $pdo,
    string $login,
    string $code,
    string $newPassword,
    string $newPassword2
): bool|string {
    return tp_admin_password_complete_reset($pdo, $login, $code, $newPassword, $newPassword2);
}
