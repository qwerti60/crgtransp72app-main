<?php
declare(strict_types=1);

/**
 * Подключение firebase/php-jwt (vendor на shared hosting или локально).
 */
function crg_jwt_autoload(): bool
{
    static $loaded = null;
    if ($loaded !== null) {
        return $loaded;
    }

    $candidates = [
        '/var/www/u2395188/data/vendor/autoload.php',
        dirname(__DIR__, 2) . '/vendor/autoload.php',
        dirname(__DIR__) . '/vendor/autoload.php',
    ];

    foreach ($candidates as $path) {
        if (is_readable($path)) {
            require_once $path;
            break;
        }
    }

    return $loaded = class_exists(\Firebase\JWT\JWT::class);
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

    return \Firebase\JWT\JWT::encode($payload, crg_jwt_secret(), 'HS256');
}
