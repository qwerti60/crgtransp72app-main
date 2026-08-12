<?php
declare(strict_types=1);

/**
 * Подключение БД: databd.local.php (локально) или databd.php (сервер).
 * После require доступны: $host, $username, $password, $dbname (и в $GLOBALS).
 *
 * Безопасно подключать через require_once из любого места (в т.ч. из функций).
 */
if (!isset($GLOBALS['host'], $GLOBALS['username'], $GLOBALS['password'], $GLOBALS['dbname'])) {
    $root = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : __DIR__;
    $localPath = $root . '/databd.local.php';
    if (is_readable($localPath)) {
        require_once $localPath;
    } elseif (is_readable($root . '/databd.php')) {
        require_once $root . '/databd.php';
    } else {
        throw new RuntimeException('Не найден databd.local.php или databd.php в ' . $root);
    }

    // databd*.php задаёт локальные переменные — сохраняем в $GLOBALS
    if (isset($host, $username, $password, $dbname)) {
        $GLOBALS['host'] = (string) $host;
        $GLOBALS['username'] = (string) $username;
        $GLOBALS['password'] = (string) $password;
        $GLOBALS['dbname'] = (string) $dbname;
    }
}

if (!isset($GLOBALS['host'], $GLOBALS['username'], $GLOBALS['password'], $GLOBALS['dbname'])) {
    throw new RuntimeException('В файле подключения к БД должны быть $host, $username, $password, $dbname');
}

// Экспорт в текущую область (для старых скриптов с top-level require)
$host = $GLOBALS['host'];
$username = $GLOBALS['username'];
$password = $GLOBALS['password'];
$dbname = $GLOBALS['dbname'];

if (!function_exists('crg_db_config')) {
    /**
     * @return array{host: string, username: string, password: string, dbname: string}
     */
    function crg_db_config(): array
    {
        if (!isset($GLOBALS['host'], $GLOBALS['username'], $GLOBALS['password'], $GLOBALS['dbname'])) {
            throw new RuntimeException('В файле подключения к БД должны быть $host, $username, $password, $dbname');
        }

        return [
            'host' => (string) $GLOBALS['host'],
            'username' => (string) $GLOBALS['username'],
            'password' => (string) $GLOBALS['password'],
            'dbname' => (string) $GLOBALS['dbname'],
        ];
    }
}

if (!function_exists('crg_mysqli_connect')) {
    function crg_mysqli_connect(): mysqli
    {
        $db = crg_db_config();
        $conn = new mysqli($db['host'], $db['username'], $db['password'], $db['dbname']);
        if ($conn->connect_error) {
            throw new RuntimeException('Ошибка подключения к БД: ' . $conn->connect_error);
        }
        $conn->set_charset('utf8mb4');

        return $conn;
    }
}

if (!function_exists('crg_pdo_connect')) {
    function crg_pdo_connect(): PDO
    {
        $db = crg_db_config();
        $pdo = new PDO(
            sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $db['host'], $db['dbname']),
            $db['username'],
            $db['password'],
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]
        );

        return $pdo;
    }
}
