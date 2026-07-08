<?php
declare(strict_types=1);

/**
 * Подключение БД: databd.local.php (локально) или databd.php (сервер).
 * После require в глобальной области доступны: $host, $username, $password, $dbname.
 */
if (!isset($host, $username, $password, $dbname)) {
    $root = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : __DIR__;
    $localPath = $root . '/databd.local.php';
    if (is_readable($localPath)) {
        require $localPath;
    } elseif (is_readable($root . '/databd.php')) {
        require $root . '/databd.php';
    } else {
        throw new RuntimeException('Не найден databd.local.php или databd.php в ' . $root);
    }
}

/**
 * @return array{host: string, username: string, password: string, dbname: string}
 */
function crg_db_config(): array
{
    global $host, $username, $password, $dbname;

    if (!isset($host, $username, $password, $dbname)) {
        throw new RuntimeException('В файле подключения к БД должны быть $host, $username, $password, $dbname');
    }

    return [
        'host' => (string) $host,
        'username' => (string) $username,
        'password' => (string) $password,
        'dbname' => (string) $dbname,
    ];
}

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
