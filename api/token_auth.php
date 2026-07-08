<?php
declare(strict_types=1);

require_once __DIR__ . '/include/jwt_bootstrap.php';

/**
 * Возвращает idusers по JWT (после логина) или по FCM push-токену (старые сессии).
 */
function resolveUserIdFromToken(PDO $pdo, string $token): ?int
{
    if (substr_count($token, '.') === 2) {
        $decoded = crg_jwt_decode($token);
        if ($decoded !== null) {
            $data = isset($decoded->data) ? (array) $decoded->data : [];

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
        }
    }

    $stmt = $pdo->prepare('SELECT idusers FROM users WHERE fcm_token = ? LIMIT 1');
    $stmt->execute([$token]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row ? (int) $row['idusers'] : null;
}
