<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/include/mail_config.php';
require_once __DIR__ . '/include/admin_mail.php';

$settings = crg_mail_settings();
$key = isset($_GET['key']) ? (string) $_GET['key'] : '';
$to = isset($_GET['to']) ? trim((string) $_GET['to']) : '';

$expectedKey = $settings['diag_secret'] !== '' ? $settings['diag_secret'] : 'crg-mail-diag';

if ($key === '' || !hash_equals($expectedKey, $key)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Укажите key (см. $crg_mail_diag_secret в mail.local.php)'], JSON_UNESCAPED_UNICODE);
    exit;
}

$result = [
    'status' => 'ok',
    'mail_local_exists' => crg_mail_local_exists(),
    'mail_configured' => crg_mail_is_configured(),
    'from' => crg_mail_from_address(),
    'smtp' => $settings['smtp'] !== null ? [
        'host' => $settings['smtp']['host'],
        'port' => $settings['smtp']['port'],
        'secure' => $settings['smtp']['secure'],
        'user' => $settings['smtp']['user'],
    ] : null,
];

if ($to !== '' && filter_var($to, FILTER_VALIDATE_EMAIL)) {
    $log = [];
    $subject = 'Тест почты CRG Transp72';
    $body = 'Если вы видите это письмо — отправка работает. ' . date('Y-m-d H:i:s');
    $send = false;

    if ($settings['smtp'] !== null) {
        $send = crg_mail_smtp_send($settings['smtp'], crg_mail_from_address(), $to, $subject, $body, $log);
        $result['smtp_send'] = $send === true ? 'ok' : $send;
        $result['smtp_log'] = $log;
    } else {
        $result['smtp_send'] = 'smtp not configured';
    }

    if ($send !== true) {
        $hosting = crg_mail_hosting_send(crg_mail_from_address(), $to, $subject, $body);
        $result['hosting_mail_send'] = $hosting === true ? 'ok' : $hosting;
    }
} else {
    $result['hint'] = 'Добавьте &to=ваш@email.ru для тестовой отправки';
}

echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
