<?php
declare(strict_types=1);

/**
 * Минимальный JWT HS256 без composer (для shared hosting).
 */

function crg_jwt_b64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function crg_jwt_b64url_decode(string $data): string|false
{
    $remainder = strlen($data) % 4;
    if ($remainder > 0) {
        $data .= str_repeat('=', 4 - $remainder);
    }

    return base64_decode(strtr($data, '-_', '+/'), true);
}

/**
 * @param array<string, mixed> $payload
 */
function crg_jwt_hs256_encode(array $payload, string $secret): string
{
    $header = crg_jwt_b64url_encode((string) json_encode(['typ' => 'JWT', 'alg' => 'HS256'], JSON_UNESCAPED_UNICODE));
    $body = crg_jwt_b64url_encode((string) json_encode($payload, JSON_UNESCAPED_UNICODE));
    $signature = crg_jwt_b64url_encode(hash_hmac('sha256', $header . '.' . $body, $secret, true));

    return $header . '.' . $body . '.' . $signature;
}

/**
 * @return object|null
 */
function crg_jwt_hs256_decode(string $jwt, string $secret): ?object
{
    $parts = explode('.', $jwt);
    if (count($parts) !== 3) {
        return null;
    }

    [$headerB64, $payloadB64, $signatureB64] = $parts;
    $expected = crg_jwt_b64url_encode(hash_hmac('sha256', $headerB64 . '.' . $payloadB64, $secret, true));
    if (!hash_equals($expected, $signatureB64)) {
        return null;
    }

    $headerRaw = crg_jwt_b64url_decode($headerB64);
    $payloadRaw = crg_jwt_b64url_decode($payloadB64);
    if ($headerRaw === false || $payloadRaw === false) {
        return null;
    }

    $header = json_decode($headerRaw);
    $payload = json_decode($payloadRaw);
    if (!is_object($header) || !is_object($payload)) {
        return null;
    }

    if (($header->alg ?? '') !== 'HS256') {
        return null;
    }

    $now = time();
    if (isset($payload->nbf) && (int) $payload->nbf > $now) {
        return null;
    }
    if (isset($payload->exp) && (int) $payload->exp < $now) {
        return null;
    }

    return $payload;
}
