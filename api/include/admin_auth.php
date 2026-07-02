<?php
declare(strict_types=1);

function tp_admin_bearer(): ?string
{
    $fromHeader = tp_bearer_token();
    if ($fromHeader !== null && $fromHeader !== '') {
        return $fromHeader;
    }
    if (session_status() === PHP_SESSION_ACTIVE) {
        $t = $_SESSION['admin_web_token'] ?? '';
        if (is_string($t) && $t !== '') {
            return $t;
        }
    }

    return null;
}

function tp_admin_authorized(PDO $pdo): bool
{
    $actual = tp_admin_bearer();
    if ($actual === null || $actual === '') {
        return false;
    }

    try {
        $st = $pdo->prepare(
            'SELECT id FROM admin_accounts WHERE token = ? AND token IS NOT NULL AND token != \'\' LIMIT 1'
        );
        $st->execute([$actual]);

        return $st->fetch() !== false;
    } catch (Throwable $e) {
        return false;
    }
}

/**
 * @return array{id: int, login: string, email: string}|null
 */
function tp_admin_session_from_bearer(PDO $pdo, string $bearer): ?array
{
    try {
        $st = $pdo->prepare(
            'SELECT id, login, email FROM admin_accounts WHERE token = ? AND token IS NOT NULL AND token != \'\' LIMIT 1'
        );
        $st->execute([$bearer]);
        $row = $st->fetch();
        if ($row === false) {
            return null;
        }

        return [
            'id' => (int) $row['id'],
            'login' => (string) $row['login'],
            'email' => trim((string) ($row['email'] ?? '')),
        ];
    } catch (Throwable $e) {
        return null;
    }
}

/**
 * @return array{id: int, login: string, email: string}|null
 */
function tp_admin_current_account(PDO $pdo): ?array
{
    $bearer = tp_admin_bearer();
    if ($bearer === null || $bearer === '') {
        return null;
    }

    return tp_admin_session_from_bearer($pdo, $bearer);
}
