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
        require $loader;
    } elseif (!isset($host, $username, $password, $dbname)) {
        $localPath = $root . '/databd.local.php';
        if (is_readable($localPath)) {
            require $localPath;
        } elseif (is_readable($root . '/databd.php')) {
            require $root . '/databd.php';
        }
    }
    if (!isset($host, $username, $password, $dbname)) {
        http_response_code(500);
        header('Content-Type: text/plain; charset=utf-8');
        echo "В файле подключения к БД должны быть \$host, \$username, \$password, \$dbname\n";
        exit;
    }

    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $host, $dbname);
    $pdo = new PDO($dsn, $username, $password, tp_pdo_driver_options());

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
