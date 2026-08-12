<?php
/**
 * Секреты Альфа-Банка / payment gateway.
 * Скопируйте в payment.local.php и заполните (файл не в git).
 *
 * На сервере для api_test можно взять готовый payment-proxy с prod:
 *   cp ../api/payment.local.php ./payment.local.php
 * или скопировать весь боевой payment-proxy.php, если он монолитный.
 */
declare(strict_types=1);

return [
    // Тестовый шлюз: https://alfa.rbsuat.com/payment/rest/
    // Боевой — URL из кабинета банка (как на prod /api/payment-proxy.php)
    'bank_url' => 'https://alfa.rbsuat.com/payment/rest/',
    'username' => 'ВАШ_ЛОГИН_ШЛЮЗА',
    'password' => 'ВАШ_ПАРОЛЬ_ШЛЮЗА',
];
