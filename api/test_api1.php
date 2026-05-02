<?php
// --- НАСТРОЙКИ ---
define('BANK_USERNAME', 'r-gruzoperevozki72-api'); // ВАШ ЛОГИН ИЗ ЛИЧНОГО КАБИНЕТА БАНКА
define('BANK_PASSWORD', 'Gruzoperevozki72*?123');         // ВАШ ПАРОЛЬ ИЗ ЛИЧНОГО КАБИНЕТА БАНКА
define('BANK_URL', 'https://alfa.rbsuat.com/payment/rest/'); // Тестовый URL

// --- ЛОГИКА ---
$isPostRequest = ($_SERVER['REQUEST_METHOD'] === 'POST');
$responseData = '';
$errorMessage = '';
$debugLog = ''; // Переменная для хранения технического лога

if ($isPostRequest) {
    // Безопасный сбор данных (защита от перезаписи пароля)
    $method = $_POST['method'] ?? '';
    $orderId = $_POST['orderId'] ?? '';

    if (empty($method)) {
        $errorMessage = 'Parameter "method" is required.';
    } else {
        // Формируем массив данных ТОЛЬКО из разрешенных полей
        $data = [
            'userName' => BANK_USERNAME,
            'password' => BANK_PASSWORD,
            'orderId' => $orderId,
        ];
        
        // Удаляем пустые необязательные параметры, чтобы не засорять запрос
        $data = array_filter($data, function($value) {
            return $value !== '';
        });

        // --- НАЧАЛО ОТРЛАДКИ: Формируем текст лога ---
        $debugLog = "--- DEBUG LOG ---\n";
        $debugLog .= "URL: " . BANK_URL . $method . "\n";
        $debugLog .= "Метод: " . $method . "\n";
        $debugLog .= "Отправляемые данные (POST):\n";
        $debugLog .= print_r($data, true); // print_r выводит массив в виде строки
        $debugLog .= "\n";

        // --- ОТПРАВКА ЗАПРОСА В БАНК ---
        $ch = curl_init(BANK_URL . $method);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $data, // Передаем как МАССИВ для корректного экранирования спецсимволов!
            CURLOPT_SSL_VERIFYPEER => true,
        ]);

        $response = curl_exec($ch);
        
        // Проверка на ошибки самого cURL (например, нет интернета)
        if(curl_errno($ch)){
            $errorMessage = 'Ошибка cURL: ' . curl_error($ch);
        }
        
        curl_close($ch);

        // Добавляем ответ банка в лог
        $debugLog .= "--- ОТВЕТ БАНКА ---\n";
        $debugLog .= $response;
        $debugLog .= "\n----------------------\n";

        if (!$errorMessage) {
            $responseData = $response;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Тест API Банка</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f4f4f9; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #333; }
        
        form { display: grid; grid-template-columns: 1fr 2fr; gap: 15px; }
        label { font-weight: bold; text-align: right; padding-right: 10px; }
        
        input[type="text"], input[type="number"], textarea { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; }
        
        button { grid-column: span 2; background: #28a745; color: white; border: none; padding: 12px; cursor: pointer; font-size: 16px; border-radius: 4px; transition: background 0.3s; }
        button:hover { background: #218838; }
        
        .response-block { margin-top: 30px; padding: 20px; background: #e9ecef; border-radius: 4px; white-space: pre-wrap; font-family: 'Courier New', Courier, monospace; color: #000; max-height: 400px; overflow-y: auto; }
        
        .error-block { margin-top: 30px; padding: 20px; background: #f8d7da; border-radius: 4px; color: #721c24; }
        
        .debug-block { margin-top: 40px; padding: 15px; background:#f0f0f0; border-radius:5px;}
    </style>
</head>
<body>
<div class="container">
    <h1>Тестирование API (Скрипт-посредник)</h1>
    
    <form method="POST">
        
        <div>
            <label for="method">Метод API:</label>
            <input type="text" id="method" name="method" required placeholder="register.do">
        </div>

        <div>
            <label for="orderId">Номер заказа:</label>
            <input type="text" id="orderId" name="orderId" required placeholder="ORDER_777">
        </div>

        <div>
            <label for="amount">Сумма:</label>
            <input type="number" id="amount" name="amount" required placeholder="100.00">
        </div>

         <div>
            <label for="returnUrl">URL возврата (Success):</label>
            <input type="text" id="returnUrl" name="returnUrl" required placeholder="https://ivnovav.ru/success">
         </div>
        
         <div>
            <label for="failUrl">URL возврата (Fail):</label>
            <input type="text" id="failUrl" name="failUrl" required placeholder="https://ivnovav.ru/fail">
         </div>
        
         <div>
            <label for="description">Описание:</label>
            <textarea id="description" name="description"></textarea>
         </div>

        <button type="submit">Отправить запрос в Банк</button>
    </form>

    <?php if ($isPostRequest): ?>
    
    <?php if (!empty($responseData)): ?>
    <div class="response-block">
        <h2>Ответ от Банка:</h2>
        <?php echo '<pre>' . htmlspecialchars($responseData) . '</pre>'; ?>
    </div>
    <?php endif; ?>

    <?php if (!empty($errorMessage)): ?>
    <div class="error-block">
        <h2>Ошибка:</h2>
        <?php echo htmlspecialchars($errorMessage); ?>
    </div>
    <?php endif; ?>

    <!-- НОВЫЙ БЛОК: Вывод отладочного лога -->
    <?php if (!empty($debugLog)): ?>
    <div class="debug-block">
        <h3 style="color:#333;">Технический лог (Debug)</h3>
        <pre style="background:#fff; padding:10px; border:1px solid #ccc;"><?php echo htmlspecialchars($debugLog); ?></pre>
    </div>
    <?php endif; ?>
    
    <?php endif; ?>
</div>
</body>
</html>