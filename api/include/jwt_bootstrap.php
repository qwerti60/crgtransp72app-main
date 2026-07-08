<?php
declare(strict_types=1);

require_once __DIR__ . '/jwt_hs256.php';

/**
 * Пути к composer vendor (если firebase/php-jwt уже установлен на хостинге).
 *
 * @return list<string>
 */
function crg_jwt_vendor_paths(): array
{
    $apiDir = dirname(__DIR__);
    $paths = [];

    $paths[] = $apiDir . '/vendor/autoload.php';

    for ($up = 1; $up <= 5; $up++) {
        $paths[] = dirname($apiDir, $up) . '/vendor/autoload.php';
    }

    $paths[] = '/var/www/u3569916/data/vendor/autoload.php';
    $paths[] = '/var/www/u2395188/data/vendor/autoload.php';

    return array_values(array_unique($paths));
}

/**
 * Подключение firebase/php-jwt при наличии vendor; иначе встроенный HS256.
 */
function crg_jwt_autoload(): bool
{
    static $loaded = null;
    if ($loaded !== null) {
        return $loaded;
    }

    foreach (crg_jwt_vendor_paths() as $path) {
        if (is_readable($path)) {
            require_once $path;
            if (class_exists(\Firebase\JWT\JWT::class)) {
                return $loaded = true;
            }
        }
    }

    return $loaded = true;
}

function crg_jwt_secret(): string
{
    return '789456123';
}

/**
 * @param array<string, mixed> $payload
 */
function crg_jwt_encode(array $payload): ?string
{
    if (!crg_jwt_autoload()) {
        return null;
    }

    try {
        if (class_exists(\Firebase\JWT\JWT::class, false)) {
            return \Firebase\JWT\JWT::encode($payload, crg_jwt_secret(), 'HS256');
        }

        return crg_jwt_hs256_encode($payload, crg_jwt_secret());
    } catch (Throwable $e) {
        return null;
    }
}

/**
 * @return object|null
 */
function crg_jwt_decode(string $jwt): ?object
{
    if (!crg_jwt_autoload()) {
        return null;
    }

    try {
        if (class_exists(\Firebase\JWT\JWT::class, false) && class_exists(\Firebase\JWT\Key::class, false)) {
            return \Firebase\JWT\JWT::decode($jwt, new \Firebase\JWT\Key(crg_jwt_secret(), 'HS256'));
        }

        return crg_jwt_hs256_decode($jwt, crg_jwt_secret());
    } catch (Throwable $e) {
        return null;
    }
}
