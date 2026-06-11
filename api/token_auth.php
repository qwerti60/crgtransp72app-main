<?php
require_once '/var/www/u2395188/data/vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

/**
 * Возвращает idusers по JWT (после логина) или по FCM push-токену (старые сессии).
 */
function resolveUserIdFromToken(PDO $pdo, string $token): ?int
{
    if (substr_count($token, '.') === 2) {
        try {
            $decoded = JWT::decode($token, new Key('789456123', 'HS256'));
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
