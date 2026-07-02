<?php
declare(strict_types=1);

function crg_fcm_base64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function crg_fcm_service_account_candidates(): array
{
    $candidates = [];

    $envPath = getenv('CRG_FCM_SERVICE_ACCOUNT');
    if (is_string($envPath) && $envPath !== '') {
        $candidates[] = $envPath;
    }

    $apiRoot = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : dirname(__DIR__);
    $candidates[] = $apiRoot . '/service_account.json';
    $candidates[] = dirname($apiRoot) . '/assets/service_account.json';

    return array_values(array_unique($candidates));
}

function crg_fcm_service_account_path(): string
{
    foreach (crg_fcm_service_account_candidates() as $path) {
        if (is_readable($path)) {
            return $path;
        }
    }

    $candidates = crg_fcm_service_account_candidates();

    return $candidates[0] ?? (dirname(__DIR__) . '/service_account.json');
}

/** @return array{ok: bool, path: string, hint: string} */
function crg_fcm_config_status(): array
{
    $expected = crg_fcm_service_account_path();
    $serviceAccount = crg_fcm_load_service_account();
    if ($serviceAccount !== null) {
        $projectId = (string) ($serviceAccount['project_id'] ?? '');
        $hint = 'Проект Firebase: ' . $projectId;
        if ($projectId !== '' && $projectId !== 'crgtransp72app') {
            $hint .= ' (ожидается crgtransp72app — скачайте ключ из правильного проекта)';
        }
        $oauth = crg_fcm_acquire_access_token($serviceAccount);
        if ($oauth === false) {
            $hint .= '. OAuth: ' . (crg_fcm_last_error() ?? 'ошибка');
        } else {
            $hint .= '. OAuth: OK';
        }

        return [
            'ok' => $oauth !== false,
            'path' => crg_fcm_service_account_path(),
            'hint' => $hint,
        ];
    }

    return [
        'ok' => false,
        'path' => $expected,
        'hint' => 'Загрузите ключ сервисного аккаунта Firebase (проект crgtransp72app) в '
            . 'api/service_account.json на сервере. Файл не должен быть доступен из браузера.',
    ];
}

function crg_fcm_is_configured(): bool
{
    return crg_fcm_load_service_account() !== null;
}

/**
 * @return array<string, mixed>|null
 */
function crg_fcm_load_service_account(): ?array
{
    foreach (crg_fcm_service_account_candidates() as $path) {
        if (!is_readable($path)) {
            continue;
        }
        $data = json_decode((string) file_get_contents($path), true);

        if (
            is_array($data)
            && !empty($data['client_email'])
            && !empty($data['private_key'])
            && !empty($data['project_id'])
        ) {
            return $data;
        }
    }

    return null;
}

function crg_fcm_looks_like_session_jwt(string $token): bool
{
    // Сессия после login (HS256) — не путать с FCM registration token.
    return preg_match('/^eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$/', $token) === 1;
}

/** @return true|string null = ok, string = причина отклонения */
function crg_fcm_validate_device_token(string $token): bool|string
{
    $token = trim($token);
    if ($token === '') {
        return 'пустой FCM-токен';
    }
    if (crg_fcm_looks_like_session_jwt($token)) {
        return 'в БД записан JWT сессии вместо FCM-токена (выйдите и войдите в приложении заново)';
    }
    if (strlen($token) < 32 || strlen($token) > 4096) {
        return 'некорректная длина FCM-токена';
    }
    if (preg_match('/^[a-zA-Z0-9_:\-]+$/', $token) !== 1) {
        return 'некорректные символы в FCM-токене';
    }

    return true;
}

function crg_fcm_normalize_private_key(string $privateKey): string
{
    $privateKey = trim($privateKey);
    if (str_contains($privateKey, '\\n')) {
        $privateKey = str_replace('\\n', "\n", $privateKey);
    }

    return $privateKey;
}

/** @var string|null */
$GLOBALS['crg_fcm_last_error'] = null;
/** @var string|null */
$GLOBALS['crg_fcm_last_message_id'] = null;

function crg_fcm_last_error(): ?string
{
    return $GLOBALS['crg_fcm_last_error'] ?? null;
}

function crg_fcm_last_message_id(): ?string
{
    return $GLOBALS['crg_fcm_last_message_id'] ?? null;
}

function crg_fcm_android_channel_id(): string
{
    return 'crg_high_importance';
}

/**
 * @return string|false
 */
function crg_fcm_acquire_access_token(?array $serviceAccount = null, bool $forceRefresh = false)
{
    static $cachedToken = null;
    static $cachedUntil = 0;

    if (
        !$forceRefresh
        && is_string($cachedToken)
        && $cachedToken !== ''
        && time() < $cachedUntil
    ) {
        return $cachedToken;
    }

    $GLOBALS['crg_fcm_last_error'] = null;

    if ($serviceAccount === null) {
        $serviceAccount = crg_fcm_load_service_account();
    }
    if ($serviceAccount === null) {
        $status = crg_fcm_config_status();
        $GLOBALS['crg_fcm_last_error'] = 'Firebase service_account.json не настроен ('
            . $status['hint'] . ')';

        return false;
    }

    if (!function_exists('curl_init')) {
        $GLOBALS['crg_fcm_last_error'] = 'cURL не доступен на сервере';

        return false;
    }

    $privateKey = crg_fcm_normalize_private_key((string) $serviceAccount['private_key']);
    $now = time();
    $jwtHeader = ['alg' => 'RS256', 'typ' => 'JWT'];
    $jwtClaim = [
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600,
    ];

    $jwtUnsigned = crg_fcm_base64url_encode(json_encode($jwtHeader, JSON_UNESCAPED_UNICODE))
        . '.' . crg_fcm_base64url_encode(json_encode($jwtClaim, JSON_UNESCAPED_UNICODE));
    $signature = '';
    if (!openssl_sign($jwtUnsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256)) {
        $GLOBALS['crg_fcm_last_error'] = 'Не удалось подписать JWT (проверьте private_key в service_account.json)';

        return false;
    }

    $jwt = $jwtUnsigned . '.' . crg_fcm_base64url_encode($signature);

    $tokenCurl = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt_array($tokenCurl, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
        CURLOPT_POSTFIELDS => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]),
    ]);

    $tokenResponse = curl_exec($tokenCurl);
    $tokenStatus = (int) curl_getinfo($tokenCurl, CURLINFO_HTTP_CODE);
    curl_close($tokenCurl);

    if ($tokenResponse === false || $tokenStatus !== 200) {
        $detail = '';
        if ($tokenResponse !== false) {
            $decoded = json_decode((string) $tokenResponse, true);
            if (is_array($decoded)) {
                $detail = trim((string) ($decoded['error_description'] ?? $decoded['error'] ?? ''));
            }
        }
        $GLOBALS['crg_fcm_last_error'] = 'OAuth Firebase HTTP ' . $tokenStatus
            . ($detail !== '' ? ': ' . $detail : '');

        return false;
    }

    $tokenData = json_decode((string) $tokenResponse, true);
    $accessToken = is_array($tokenData) ? trim((string) ($tokenData['access_token'] ?? '')) : '';
    if ($accessToken === '') {
        $GLOBALS['crg_fcm_last_error'] = 'Пустой access token Firebase';

        return false;
    }

    $cachedToken = $accessToken;
    $cachedUntil = time() + 3300;

    return $accessToken;
}

/** @param array<string, mixed> $decoded */
function crg_fcm_format_send_error(int $httpStatus, array $decoded, string $projectId, string $deviceToken): string
{
    $detail = trim((string) ($decoded['error']['message'] ?? ''));
    if ($detail === '') {
        $detail = trim((string) ($decoded['error']['status'] ?? ''));
    }

    $apnsInvalid = false;
    $thirdParty = false;
    if (!empty($decoded['error']['details']) && is_array($decoded['error']['details'])) {
        foreach ($decoded['error']['details'] as $item) {
            if (!is_array($item)) {
                continue;
            }
            $type = (string) ($item['@type'] ?? '');
            if (str_contains($type, 'ApnsError')) {
                $reason = (string) ($item['reason'] ?? '');
                if (strtoupper($reason) === 'INVALIDPROVIDERTOKEN') {
                    $apnsInvalid = true;
                }
            }
            if (str_contains($type, 'FcmError')) {
                $code = (string) ($item['errorCode'] ?? '');
                if ($code === 'THIRD_PARTY_AUTH_ERROR') {
                    $thirdParty = true;
                }
                if ($code === 'INVALID_ARGUMENT' || $code === 'UNREGISTERED') {
                    return 'FCM-токен не зарегистрирован в Firebase (Invalid registration token). '
                        . 'iOS: только реальный iPhone (не симулятор), разрешите уведомления, '
                        . 'подождите 10 сек после входа и войдите снова.';
                }
            }
            if (str_contains($type, 'BadRequest') && !empty($item['fieldViolations'])) {
                foreach ($item['fieldViolations'] as $violation) {
                    if (!is_array($violation)) {
                        continue;
                    }
                    $field = (string) ($violation['field'] ?? '');
                    $desc = (string) ($violation['description'] ?? '');
                    if ($field === 'message.token' || str_contains(strtolower($desc), 'registration token')) {
                        return 'FCM-токен не зарегистрирован в Firebase (Invalid registration token). '
                            . 'iOS: только реальный iPhone (не симулятор), Настройки → Уведомления → включены, '
                            . 'подождите 10 сек после входа. Если не помогло — удалите приложение и установите заново.';
                    }
                }
            }
        }
    }

    if ($apnsInvalid || $thirdParty) {
        return 'iOS push: неверный APNs-ключ в Firebase (InvalidProviderToken). '
            . 'Firebase → Cloud Messaging → приложение ru.app72.crgtransp72app → '
            . 'загрузите один и тот же .p8 в Development И Production (Key ID + Team ID 9D79UST58L). '
            . 'После этого пользователь #5 перелогинивается на iPhone.';
    }

    if ($httpStatus === 401 && crg_fcm_looks_like_session_jwt($deviceToken)) {
        return 'Некорректный FCM-токен: в БД JWT сессии — пользователь должен перелогиниться';
    }

    $suffix = $detail !== '' ? ': ' . $detail : '';
    if ($httpStatus === 401) {
        $suffix .= ' (проект ' . $projectId
            . ': проверьте api/service_account.json и Firebase Cloud Messaging API)';
    }

    return 'Firebase отклонил push (HTTP ' . $httpStatus . ')' . $suffix;
}

/** @return true|string */
function crg_fcm_send(
    string $deviceToken,
    string $title,
    string $body,
    bool $retryOnAuth = true,
    ?string $deliveryTag = null
): bool|string {
    $deviceToken = trim($deviceToken);
    $title = trim($title);
    $body = trim($body);

    if ($deviceToken === '' || $title === '' || $body === '') {
        return 'Не указаны token, заголовок или текст уведомления';
    }

    $tokenCheck = crg_fcm_validate_device_token($deviceToken);
    if ($tokenCheck !== true) {
        return 'Некорректный FCM-токен устройства: ' . $tokenCheck;
    }

    $serviceAccount = crg_fcm_load_service_account();
    if ($serviceAccount === null) {
        $status = crg_fcm_config_status();

        return 'Firebase service_account.json не настроен на сервере ('
            . $status['hint'] . ')';
    }

    $accessToken = crg_fcm_acquire_access_token($serviceAccount);
    if ($accessToken === false) {
        return crg_fcm_last_error() ?? 'Не удалось получить токен Firebase';
    }

    if ($deliveryTag === null || $deliveryTag === '') {
        $deliveryTag = crg_fcm_delivery_tag();
    }

    $GLOBALS['crg_fcm_last_message_id'] = null;

    $message = [
        'message' => [
            'token' => $deviceToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                    'apns-push-type' => 'alert',
                ],
                'payload' => [
                    'aps' => [
                        'alert' => ['title' => $title, 'body' => $body],
                        'sound' => 'default',
                        'badge' => 1,
                    ],
                ],
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => crg_fcm_android_channel_id(),
                    'sound' => 'default',
                    'tag' => $deliveryTag,
                    'notification_count' => 1,
                ],
            ],
        ],
    ];

    $projectId = (string) $serviceAccount['project_id'];
    $sendUrl = 'https://fcm.googleapis.com/v1/projects/' . $projectId . '/messages:send';
    $sendCurl = curl_init($sendUrl);
    $payload = json_encode($message, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    curl_setopt_array($sendCurl, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json; charset=UTF-8',
            'Accept: application/json',
        ],
        CURLOPT_POSTFIELDS => $payload,
    ]);

    $sendResponse = curl_exec($sendCurl);
    $sendStatus = (int) curl_getinfo($sendCurl, CURLINFO_HTTP_CODE);
    curl_close($sendCurl);

    if ($sendStatus === 401 && $retryOnAuth) {
        $accessToken = crg_fcm_acquire_access_token($serviceAccount, true);
        if ($accessToken !== false) {
            return crg_fcm_send($deviceToken, $title, $body, false, $deliveryTag);
        }
    }

    if ($sendResponse === false || $sendStatus < 200 || $sendStatus >= 300) {
        if ($sendResponse === false) {
            return 'Firebase: нет ответа при отправке push';
        }

        $decoded = json_decode((string) $sendResponse, true);
        if (!is_array($decoded)) {
            return 'Firebase отклонил push (HTTP ' . $sendStatus . ')';
        }

        return crg_fcm_format_send_error($sendStatus, $decoded, $projectId, $deviceToken);
    }

    $decoded = json_decode((string) $sendResponse, true);
    if (!is_array($decoded) || trim((string) ($decoded['name'] ?? '')) === '') {
        return 'Firebase: неожиданный ответ при отправке push (HTTP ' . $sendStatus . ')';
    }

    $GLOBALS['crg_fcm_last_message_id'] = (string) $decoded['name'];

    return true;
}

/**
 * Проверяет, что токен зарегистрирован в Firebase (без видимого уведомления).
 *
 * @return true|string
 */
function crg_fcm_probe_token(string $deviceToken, bool $retryOnAuth = true): bool|string
{
    $deviceToken = trim($deviceToken);
    if ($deviceToken === '') {
        return 'Пустой FCM-токен';
    }

    $tokenCheck = crg_fcm_validate_device_token($deviceToken);
    if ($tokenCheck !== true) {
        return 'Некорректный FCM-токен: ' . $tokenCheck;
    }

    $serviceAccount = crg_fcm_load_service_account();
    if ($serviceAccount === null) {
        return 'Firebase service_account.json не настроен';
    }

    $accessToken = crg_fcm_acquire_access_token($serviceAccount);
    if ($accessToken === false) {
        return crg_fcm_last_error() ?? 'OAuth Firebase';
    }

    $message = [
        'message' => [
            'token' => $deviceToken,
            'data' => ['crg_ping' => '1'],
            'apns' => [
                'headers' => [
                    'apns-priority' => '5',
                    'apns-push-type' => 'background',
                ],
                'payload' => [
                    'aps' => ['content-available' => 1],
                ],
            ],
            'android' => ['priority' => 'normal'],
        ],
    ];

    $projectId = (string) $serviceAccount['project_id'];
    $sendUrl = 'https://fcm.googleapis.com/v1/projects/' . $projectId . '/messages:send';
    $sendCurl = curl_init($sendUrl);
    curl_setopt_array($sendCurl, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json; charset=UTF-8',
            'Accept: application/json',
        ],
        CURLOPT_POSTFIELDS => json_encode($message, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE),
    ]);

    $sendResponse = curl_exec($sendCurl);
    $sendStatus = (int) curl_getinfo($sendCurl, CURLINFO_HTTP_CODE);

    if ($sendStatus === 401 && $retryOnAuth) {
        $accessToken = crg_fcm_acquire_access_token($serviceAccount, true);
        if ($accessToken !== false) {
            return crg_fcm_probe_token($deviceToken, false);
        }
    }

    if ($sendResponse === false || $sendStatus < 200 || $sendStatus >= 300) {
        $decoded = is_string($sendResponse) ? json_decode($sendResponse, true) : null;
        if (!is_array($decoded)) {
            return 'Firebase отклонил токен (HTTP ' . $sendStatus . ')';
        }

        return crg_fcm_format_send_error($sendStatus, $decoded, $projectId, $deviceToken);
    }

    return true;
}

/** @return bool */
function crg_fcm_is_invalid_token_error(string $error): bool
{
    $error = strtoupper($error);

    return str_contains($error, 'NOT_FOUND')
        || str_contains($error, 'UNREGISTERED')
        || str_contains($error, 'INVALID_ARGUMENT')
        || str_contains($error, 'INVALID ARGUMENT')
        || str_contains($error, 'INVALID REGISTRATION TOKEN')
        || str_contains($error, 'УСТАРЕВШИЙ FCM')
        || str_contains($error, 'НЕКОРРЕКТНЫЙ FCM')
        || str_contains($error, 'JWT СЕССИИ');
}

function crg_fcm_clear_user_token(PDO $pdo, int $userId): void
{
    if ($userId <= 0) {
        return;
    }

    try {
        $st = $pdo->prepare('UPDATE users SET fcm_token = NULL WHERE idusers = ?');
        $st->execute([$userId]);
    } catch (Throwable $e) {
        // ignore
    }
}

function crg_fcm_delivery_tag(): string
{
    return 'crg-' . time() . '-' . bin2hex(random_bytes(4));
}

function crg_fcm_push_body_with_stamp(string $body): string
{
    $stamp = date('d.m.Y H:i');

    return rtrim($body) . ' (' . $stamp . ')';
}

/**
 * @return array{token: string, error: string}|null null — токена нет
 */
function crg_fcm_user_device_token(PDO $pdo, int $userId): ?array
{
    if ($userId <= 0) {
        return ['token' => '', 'error' => 'Некорректный id пользователя'];
    }

    try {
        $st = $pdo->prepare('SELECT fcm_token FROM users WHERE idusers = ? LIMIT 1');
        $st->execute([$userId]);
        $row = $st->fetch();
    } catch (Throwable $e) {
        return ['token' => '', 'error' => 'Поле fcm_token недоступно в БД'];
    }

    $token = trim((string) ($row['fcm_token'] ?? ''));
    if ($token === '') {
        return null;
    }

    $tokenCheck = crg_fcm_validate_device_token($token);
    if ($tokenCheck !== true) {
        crg_fcm_clear_user_token($pdo, $userId);

        return ['token' => '', 'error' => is_string($tokenCheck) ? $tokenCheck : 'Некорректный FCM-токен'];
    }

    return ['token' => $token, 'error' => ''];
}

/**
 * @return true|string|null null — нет FCM-токена у пользователя
 */
function crg_fcm_send_to_user(PDO $pdo, int $userId, string $title, string $body): bool|string|null
{
    $tokenData = crg_fcm_user_device_token($pdo, $userId);
    if ($tokenData === null) {
        return null;
    }
    if ($tokenData['token'] === '') {
        return $tokenData['error'] !== '' ? $tokenData['error'] : 'Нет FCM-токена';
    }

    $deliveryTag = crg_fcm_delivery_tag();
    $res = crg_fcm_send(
        $tokenData['token'],
        $title,
        crg_fcm_push_body_with_stamp($body),
        true,
        $deliveryTag
    );
    if ($res === true) {
        return true;
    }
    if (is_string($res) && crg_fcm_is_invalid_token_error($res)) {
        crg_fcm_clear_user_token($pdo, $userId);
    }

    return $res;
}

function crg_admin_notify_excerpt(string $text, int $maxLen = 220): string
{
    $text = preg_replace('/\s+/u', ' ', trim($text)) ?? trim($text);
    if (mb_strlen($text) <= $maxLen) {
        return $text;
    }

    return mb_substr($text, 0, $maxLen - 1) . '…';
}
