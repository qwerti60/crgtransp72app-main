<?php

// --- НАСТРОЙКИ ---
// Данные для подключения к платежному шлюзу (получите у Альфа-Банка)
//Логин для взаимодействия с платёжным шлюзом: r-gruzoperevozki72-api Пароль: Gruzoperevozki72*?1!
//Ссылка для входа: https://alfa.rbsuat.com/generalmp3/auth/login 
define('USERNAME', 'r-gruzoperevozki72-api'); // Замените на ваш логин
define('PASSWORD', 'Gruzoperevozki72*?1!'); // Замените на ваш пароль

// URL платежного шлюза (тестовый или боевой)
define('GATEWAY_URL', 'https://url.payment-gateway.ru/payment/rest/'); 

// URL для возврата пользователя после успешной оплаты (если требуется)
// define('RETURN_URL', 'http://your.site/success.php'); 

// --- ФУНКЦИЯ ВЗАИМОДЕЙСТВИЯ С API ---
/**
 * Отправляет POST-запрос к API платежного шлюза.
 *
 * @param string $method Метод API (например, 'register.do')
 * @param array $data Массив данных для отправки
 * @return array Декодированный ответ от шлюза
 */
function gateway($method, $data) {
    $curl = curl_init();
    curl_setopt_array($curl, [
        CURLOPT_URL => GATEWAY_URL . $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query($data),
        CURLOPT_SSL_VERIFYPEER => true, // Проверять SSL-сертификат (рекомендуется)
        CURLOPT_SSL_VERIFYHOST => 2,
    ]);

    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

    curl_close($curl);

    // Если запрос прошел успешно, декодируем JSON
    if ($httpCode == 200) {
        return json_decode($response, true) ?: ['errorCode' => 999, 'errorMessage' => 'Invalid JSON'];
    }

    // В случае сетевой ошибки
    return ['errorCode' => $httpCode, 'errorMessage' => 'HTTP Error'];
}

// --- ОБРАБОТКА ЗАПРОСА ОТ FLUTTER-ПРИЛОЖЕНИЯ ---
header('Content-Type: application/json; charset=utf-8');

// Принимаем только POST-запросы от приложения
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Получаем данные из тела запроса (JSON)
    $input = file_get_contents('php://input');
    $requestData = json_decode($input, true);

    // Проверяем наличие обязательных полей
    if (!isset($requestData['orderNumber']) || !isset($requestData['amount'])) {
        echo json_encode([
            'errorCode' => 4,
            'errorMessage' => 'Отсутствует обязательный параметр запроса (orderNumber или amount)'
        ]);
        exit;
    }

    // Подготовка данных для отправки в банк
    $data = [
        'userName' => USERNAME,
        'password' => PASSWORD,
        'orderNumber' => urlencode($requestData['orderNumber']),
        'amount' => urlencode($requestData['amount']),
        // 'returnUrl' => RETURN_URL, // Раскомментируйте, если это требует ваш банк
    ];

    // Вызов метода регистрации платежа (аналог register.do)
    $response = gateway('register.do', $data);

    // Возвращаем ответ банку в формате JSON для Flutter
    echo json_encode($response);
    exit;
}