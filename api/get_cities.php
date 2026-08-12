<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');

require __DIR__ . '/load_databd.php'; // $host, $username, $password, $dbname
$useId = isset($_GET['useId']) ? $_GET['useId'] : '';

$namex = $_GET['namex'] ?? '';
if ($namex === '') {
    http_response_code(400);
    echo json_encode(['message' => 'Missing or invalid parameter'], JSON_UNESCAPED_UNICODE);
    exit;
}

/* Получаем текущую дату */
$currentDate = date('Y-m-d'); // Формат даты MySQL: YYYY-MM-DD

/* Конфигурация справочников */
$lookups = [
    'vidt' => ['mainTable' => 'orderst', 'mainCol' => 'vidt'],
    'vidg' => ['mainTable' => 'orders', 'mainCol' => 'maxgruz'],
    'gruzchik' => ['mainTable' => 'ordersg', 'mainCol' => 'gruzchik']
];

try {
    /* 1. Подключение */
    $conn = new mysqli($host, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception('DB connection error: ' . $conn->connect_error);
    }
    $conn->set_charset('utf8mb4');

    /* 2. Ищем значение в справочниках */
    $foundLookup = $mainTable = $mainColumn = '';

    foreach ($lookups as $lookupTable => $cfg) {
        $stmt = $conn->prepare("SELECT 1 FROM {$lookupTable} WHERE name = ? LIMIT 1");
        if (!$stmt) throw new Exception($conn->error);
        $stmt->bind_param('s', $namex);
        $stmt->execute();
        $stmt->store_result();
        if ($stmt->num_rows) {
            $foundLookup = $lookupTable;
            $mainTable = $cfg['mainTable'];
            $mainColumn = $cfg['mainCol'];
            $stmt->close();
            break;
        }
        $stmt->close();
    }

    if ($foundLookup === '') {
        http_response_code(404);
        echo json_encode(['message' => 'Value not found in lookup tables'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    /* 3. Запрос к основной таблице */
if ($mainTable === 'ordersg') {
    // Особый случай для ordersg: получаем список уникальных городов без фильтрации по полю mainCol,
    // исключаем записи с определенным значением поля iduser
    $sql = "SELECT city, COUNT(*) AS cnt
            FROM {$mainTable}
            WHERE enddatez >= ? AND iduser != ?
            GROUP BY city";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) throw new Exception($conn->error);
    $stmt->bind_param('si', $currentDate, $useId); // Тип параметра зависит от типа столбца iduser
} else {
    // Общее правило для других таблиц: фильтруем по полю mainCol и проверяем дату,
    // также исключаем записи с определенным значением поля iduser
    $sql = "SELECT city, COUNT(*) AS cnt
            FROM {$mainTable}
            WHERE {$mainColumn} = ? AND enddatez >= ? AND iduser != ?
        ORDER BY city COLLATE utf8_unicode_ci";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) throw new Exception($conn->error);
    $stmt->bind_param('ssi', $namex, $currentDate, $useId); // Аналогично предыдущему случаю
}
    $stmt->execute();
    $res = $stmt->get_result();
    $rows = $res->fetch_all(MYSQLI_ASSOC);

    /* Проверка наличия городов */
    if (empty($rows)) {
        $rows[] = ['city' => 'В этом разделе ещё нет городов с объявлениями', 'cnt' => 0]; // Нет объявлений — не «город не найден»
    }

    /* 4. Формируем ответ */
    $response = [
        'lookup_table' => $foundLookup,
        'main_table' => $mainTable,
        'cities' => $rows
    ];

    echo json_encode($response, JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    error_log($e->getMessage());
    http_response_code(500);
    echo json_encode(['message' => 'Internal server error'], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($conn) && $conn instanceof mysqli) $conn->close();
}
?>