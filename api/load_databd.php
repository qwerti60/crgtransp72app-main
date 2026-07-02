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
