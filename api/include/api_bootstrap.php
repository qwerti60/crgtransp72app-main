<?php
declare(strict_types=1);

/**
 * PDO для веб-админки и API. Подключение БД — databd.local.php (локально) или databd.php.
 */

/** @return array<int, mixed> */
function tp_pdo_driver_options(): array
{
    $initCommandAttr = class_exists(\Pdo\Mysql::class, false)
        ? \Pdo\Mysql::ATTR_INIT_COMMAND
        : PDO::MYSQL_ATTR_INIT_COMMAND;

    return [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        $initCommandAttr => 'SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci',
    ];
}

function tp_pdo(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $root = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : dirname(__DIR__);
    $loader = $root . '/load_databd.php';
    if (is_readable($loader)) {
        require_once $loader;
    } else {
        $localPath = $root . '/databd.local.php';
        if (is_readable($localPath)) {
            require_once $localPath;
        } elseif (is_readable($root . '/databd.php')) {
            require_once $root . '/databd.php';
        }
        if (isset($host, $username, $password, $dbname)) {
            $GLOBALS['host'] = (string) $host;
            $GLOBALS['username'] = (string) $username;
            $GLOBALS['password'] = (string) $password;
            $GLOBALS['dbname'] = (string) $dbname;
        }
    }

    try {
        if (function_exists('crg_db_config')) {
            $db = crg_db_config();
        } elseif (isset($GLOBALS['host'], $GLOBALS['username'], $GLOBALS['password'], $GLOBALS['dbname'])) {
            $db = [
                'host' => (string) $GLOBALS['host'],
                'username' => (string) $GLOBALS['username'],
                'password' => (string) $GLOBALS['password'],
                'dbname' => (string) $GLOBALS['dbname'],
            ];
        } else {
            throw new RuntimeException('missing');
        }
    } catch (Throwable $e) {
        http_response_code(500);
        header('Content-Type: text/plain; charset=utf-8');
        echo "В файле подключения к БД должны быть \$host, \$username, \$password, \$dbname\n";
        exit;
    }

    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $db['host'], $db['dbname']);
    $pdo = new PDO($dsn, $db['username'], $db['password'], tp_pdo_driver_options());

    return $pdo;
}

function tp_bearer_token(): ?string
{
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['Authorization'] ?? '';
    if (preg_match('/Bearer\s+(\S+)/i', $h, $m)) {
        return $m[1];
    }

    return null;
}
