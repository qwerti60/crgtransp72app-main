<?php
declare(strict_types=1);

if (!function_exists('crg_jwt_autoload')) {
    foreach ([
        __DIR__ . '/include/jwt_bootstrap.php',
        __DIR__ . '/jwt_bootstrap.php',
    ] as $path) {
        if (is_readable($path)) {
            require_once $path;
            break;
        }
    }
}

if (!function_exists('crg_jwt_autoload')) {
    foreach ([
        '/var/www/u2395188/data/vendor/autoload.php',
        dirname(__DIR__) . '/vendor/autoload.php',
        dirname(__DIR__, 2) . '/vendor/autoload.php',
        __DIR__ . '/vendor/autoload.php',
    ] as $vendor) {
        if (is_readable($vendor)) {
            require_once $vendor;
            break;
        }
    }
}

if (!function_exists('crg_jwt_secret')) {
    function crg_jwt_secret(): string
    {
        return '789456123';
    }
}

if (!function_exists('crg_jwt_autoload')) {
    function crg_jwt_autoload(): bool
    {
        return class_exists(\Firebase\JWT\JWT::class, false);
    }
}

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

/**
 * Возвращает idusers по JWT (после логина) или по FCM push-токену (старые сессии).
 */
function resolveUserIdFromToken(PDO $pdo, string $token): ?int
{
    if (substr_count($token, '.') === 2) {
        try {
            if (!crg_jwt_autoload()) {
                return null;
            }
            $decoded = JWT::decode($token, new Key(crg_jwt_secret(), 'HS256'));
            $data = (array) $decoded->data;

            if (!empty($data['idusers'])) {
                return (int) $data['idusers'];
            }

            if (!empty($data['email'])) {
                $stmt = $pdo->prepare('SELECT idusers FROM users WHERE email = ? LIMIT 1');
                $stmt->execute([$data['email']]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($row) {
                    return (int) $row['idusers'];
                }
            }
        } catch (Exception $e) {
            // Пробуем поиск по FCM-токену ниже.
        }
    }

    $stmt = $pdo->prepare('SELECT idusers FROM users WHERE fcm_token = ? LIMIT 1');
    $stmt->execute([$token]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row ? (int) $row['idusers'] : null;
}

?>
