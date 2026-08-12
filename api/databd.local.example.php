<?php
/**
 * Тестовый / локальный MySQL.
 *
 * 1) cp api/databd.local.example.php api/databd.local.php
 * 2) Отредактируйте host / user / password / dbname
 * 3) Импорт схемы: mysql -u root < sql/local_dev.sql
 * 4) Запуск API: cd api && php -S 127.0.0.1:8080
 *    или: ./scripts/local_admin.sh
 *
 * Пока существует databd.local.php, весь API (через databd.php) ходит в эту БД,
 * а не в prod. На сервер databd.local.php не заливать.
 */
$host = '127.0.0.1';
$username = 'root';
$password = '';
$dbname = 'crg_local';
