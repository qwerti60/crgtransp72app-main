<?php
declare(strict_types=1);

require_once __DIR__ . '/site_config.php';

/**
 * @return list<string>
 */
function crg_mail_placeholder_passwords(): array
{
    return [
        'ПАРОЛЬ_ОТ_ПОЧТОВОГО_ЯЩИКА',
        'ВАШ_ПАРОЛЬ',
        'password',
        'change-me',
    ];
}

function crg_mail_local_path(): string
{
    return dirname(__DIR__) . '/mail.local.php';
}

function crg_mail_local_exists(): bool
{
    return is_readable(crg_mail_local_path());
}

/**
 * @return array{
 *   from: string,
 *   smtp: array{host: string, port: int, secure: string, user: string, pass: string}|null,
 *   diag_secret: string
 * }
 */
function crg_mail_settings(): array
{
    static $settings = null;
    if ($settings !== null) {
        return $settings;
    }

    $from = crg_site_mail_from();
    $smtp = null;
    $diagSecret = '';

    if (crg_mail_local_exists()) {
        $crg_mail_from = null;
        $crg_mail_smtp_enabled = false;
        $crg_mail_smtp_host = '';
        $crg_mail_smtp_port = 465;
        $crg_mail_smtp_secure = 'ssl';
        $crg_mail_smtp_user = '';
        $crg_mail_smtp_pass = '';
        $crg_mail_diag_secret = '';

        require crg_mail_local_path();

        if (is_string($crg_mail_from) && $crg_mail_from !== '' && filter_var($crg_mail_from, FILTER_VALIDATE_EMAIL)) {
            $from = $crg_mail_from;
        }

        if (is_string($crg_mail_diag_secret)) {
            $diagSecret = trim($crg_mail_diag_secret);
        }

        $passOk = is_string($crg_mail_smtp_pass)
            && $crg_mail_smtp_pass !== ''
            && !in_array($crg_mail_smtp_pass, crg_mail_placeholder_passwords(), true);

        if (!empty($crg_mail_smtp_enabled)
            && is_string($crg_mail_smtp_host) && $crg_mail_smtp_host !== ''
            && is_string($crg_mail_smtp_user) && $crg_mail_smtp_user !== ''
            && $passOk) {
            $smtp = [
                'host' => $crg_mail_smtp_host,
                'port' => (int) $crg_mail_smtp_port,
                'secure' => in_array($crg_mail_smtp_secure, ['ssl', 'tls'], true) ? $crg_mail_smtp_secure : 'ssl',
                'user' => $crg_mail_smtp_user,
                'pass' => $crg_mail_smtp_pass,
            ];
        }
    }

    return $settings = ['from' => $from, 'smtp' => $smtp, 'diag_secret' => $diagSecret];
}

function crg_mail_from_address(): string
{
    return crg_mail_settings()['from'];
}

function crg_mail_is_configured(): bool
{
    return crg_mail_local_exists() && crg_mail_settings()['smtp'] !== null;
}

/**
 * @param-out list<string> $log
 */
function crg_mail_log_step(array &$log, string $step, string $detail = ''): void
{
    $log[] = $detail === '' ? $step : ($step . ': ' . $detail);
}

/**
 * @param array{host: string, port: int, secure: string, user: string, pass: string} $smtp
 * @param list<string>|null $log
 * @return true|string
 */
function crg_mail_smtp_send(array $smtp, string $from, string $to, string $subject, string $body, ?array &$log = null): bool|string
{
    $debug = [];
    if ($log === null) {
        $log = $debug;
    }

    $secure = $smtp['secure'] ?? 'ssl';
    $host = $smtp['host'];
    $port = (int) $smtp['port'];

    $context = stream_context_create([
        'ssl' => [
            'verify_peer' => true,
            'verify_peer_name' => true,
            'peer_name' => $host,
            'SNI_enabled' => true,
        ],
    ]);

    $address = ($secure === 'ssl' ? 'ssl://' : '') . $host . ':' . $port;
    crg_mail_log_step($log, 'connect', $address);

    $fp = @stream_socket_client($address, $errno, $errstr, 25, STREAM_CLIENT_CONNECT, $context);
    if ($fp === false) {
        return 'SMTP: не удалось подключиться (' . $errstr . ')';
    }

    stream_set_timeout($fp, 25);

    $read = static function ($stream) use (&$log): string {
        $data = '';
        while (!feof($stream)) {
            $line = fgets($stream, 8192);
            if ($line === false) {
                break;
            }
            $data .= $line;
            crg_mail_log_step($log, '<<', rtrim($line));
            if (isset($line[3]) && $line[3] === ' ') {
                break;
            }
        }

        return $data;
    };

    $expect = static function ($stream, array $codes, string $step) use ($read): ?string {
        $response = $read($stream);
        if ($response === '') {
            return 'SMTP ' . $step . ': пустой ответ сервера';
        }
        $code = (int) substr($response, 0, 3);
        if (!in_array($code, $codes, true)) {
            return 'SMTP ' . $step . ': ' . trim(preg_replace('/\s+/', ' ', $response));
        }

        return null;
    };

    $write = static function ($stream, string $command, bool $logCommand = true) use (&$log): void {
        if ($logCommand) {
            $safe = str_starts_with($command, base64_encode('x')) && strlen($command) > 20
                ? '[base64]'
                : $command;
            crg_mail_log_step($log, '>>', $safe);
        }
        fwrite($stream, $command . "\r\n");
    };

    if ($err = $expect($fp, [220], 'приветствие')) {
        fclose($fp);

        return $err;
    }

    $write($fp, 'EHLO ' . crg_site_host());
    if ($err = $expect($fp, [250], 'EHLO')) {
        fclose($fp);

        return $err;
    }

    if ($secure === 'tls') {
        $write($fp, 'STARTTLS');
        if ($err = $expect($fp, [220], 'STARTTLS')) {
            fclose($fp);

            return $err;
        }
        if (!stream_socket_enable_crypto($fp, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
            fclose($fp);

            return 'SMTP: не удалось включить TLS';
        }
        $write($fp, 'EHLO ' . crg_site_host());
        if ($err = $expect($fp, [250], 'EHLO TLS')) {
            fclose($fp);

            return $err;
        }
    }

    $authed = false;
    $write($fp, 'AUTH LOGIN');
    if ($expect($fp, [334], 'AUTH LOGIN') === null) {
        $write($fp, base64_encode($smtp['user']), false);
        if ($expect($fp, [334], 'AUTH user') === null) {
            $write($fp, base64_encode($smtp['pass']), false);
            if ($expect($fp, [235], 'AUTH pass') === null) {
                $authed = true;
            }
        }
    }

    if (!$authed) {
        $plain = base64_encode("\0{$smtp['user']}\0{$smtp['pass']}");
        $write($fp, 'AUTH PLAIN ' . $plain, false);
        if ($err = $expect($fp, [235], 'AUTH PLAIN')) {
            fclose($fp);

            return 'SMTP: неверный логин или пароль почтового ящика';
        }
    }

    $write($fp, 'MAIL FROM:<' . $from . '>');
    if ($err = $expect($fp, [250], 'MAIL FROM')) {
        fclose($fp);

        return $err;
    }
    $write($fp, 'RCPT TO:<' . $to . '>');
    if ($err = $expect($fp, [250, 251], 'RCPT TO')) {
        fclose($fp);

        return $err;
    }
    $write($fp, 'DATA');
    if ($err = $expect($fp, [354], 'DATA')) {
        fclose($fp);

        return $err;
    }

    $encodedSubject = function_exists('crg_admin_mail_encode_subject')
        ? crg_admin_mail_encode_subject($subject)
        : $subject;

    $date = gmdate('D, d M Y H:i:s') . ' +0000';
    $messageId = '<' . bin2hex(random_bytes(8)) . '@' . crg_site_host() . '>';

    $payload = "Date: {$date}\r\n";
    $payload .= "Message-ID: {$messageId}\r\n";
    $payload .= "From: Грузоперевозки72 <{$from}>\r\n";
    $payload .= "To: {$to}\r\n";
    $payload .= "Subject: {$encodedSubject}\r\n";
    $payload .= "MIME-Version: 1.0\r\n";
    $payload .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $payload .= "Content-Transfer-Encoding: 8bit\r\n";
    $payload .= "\r\n";
    $payload .= str_replace(["\r\n", "\r"], ["\n", "\n"], $body);
    $payload = str_replace("\n", "\r\n", $payload);
    $payload = preg_replace('/\r\n\./', "\r\n..", $payload) ?? $payload;
    $payload .= "\r\n.\r\n";

    crg_mail_log_step($log, '>>', '[message body]');
    fwrite($fp, $payload);
    if ($err = $expect($fp, [250], 'тело письма')) {
        fclose($fp);

        return $err;
    }

    $write($fp, 'QUIT');
    fclose($fp);
    crg_mail_log_step($log, 'done', 'accepted by server');

    return true;
}

/**
 * Отправка через mail() хостинга (без внешнего SMTP).
 * @return true|string
 */
function crg_mail_hosting_send(string $from, string $to, string $subject, string $body): bool|string
{
    if (function_exists('ini_set')) {
        @ini_set('sendmail_from', $from);
    }

    $encodedSubject = function_exists('crg_admin_mail_encode_subject')
        ? crg_admin_mail_encode_subject($subject)
        : $subject;

    $headers = 'From: Грузоперевозки72 <' . $from . ">\r\n";
    $headers .= 'Reply-To: ' . $from . "\r\n";
    $headers .= 'Return-Path: ' . $from . "\r\n";
    $headers .= 'MIME-Version: 1.0' . "\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $headers .= "Content-Transfer-Encoding: 8bit\r\n";

    $ok = @mail($to, $encodedSubject, $body, $headers, '-f' . $from);

    return $ok ? true : 'mail(): сервер не принял письмо';
}
