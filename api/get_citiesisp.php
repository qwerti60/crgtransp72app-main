<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');

include 'databd.php'; // $host, $username, $password, $dbname
$useId = isset($_GET['useId']) ? $_GET['useId'] : '';

$namex = $_GET['namex'] ?? '';
if ($namex === '') {
    http_response_code(400);
    echo json_encode(['message' => 'Missing or invalid parameter'], JSON_UNESCAPED_UNICODE);
    exit;
}

// Конфигурация справочников
$lookups = [
    'vidt' => ['mainTable' => 'add_ob_vidt', 'mainCol' => 'vidt'],
    'vidg' => ['mainTable' => 'add_ob_gp', 'mainCol' => 'maxgruz'],
    'gruzchik' => ['mainTable' => 'add_ob_gr', 'mainCol' => 'gruzchik']
];

try {
    // Подключаемся к БД
    $conn = new mysqli($host, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception('DB connection error: ' . $conn->connect_error);
    }
    $conn->set_charset('utf8mb4');

    // Поиск соответствия справочнику
    $foundLookup = $mainTable = $mainColumn = '';
    foreach ($lookups as $lookupTable => $cfg) {
        $stmt = $conn->prepare("SELECT 1 FROM {$lookupTable} WHERE name = ? LIMIT 1");
        if (!$stmt) throw new Exception($conn->error);
        $stmt->bind_param('s', $namex);
        $stmt->execute();
        $stmt->store_result();
        if ($stmt->num_rows > 0) {
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

    // Счётчики по городам должны совпадать с get_ads2_new.php (тот же набор объявлений).
    $bd = match ($mainTable) {
        'add_ob_vidt' => 2,
        'add_ob_gr' => 3,
        default => 1,
    };

    if ($mainTable === 'add_ob_gr') {
        $sql = "SELECT a.city, COUNT(DISTINCT a.id) AS cnt
                FROM add_ob_gr AS a
                WHERE a.iduser IS NOT NULL
                  AND a.iduser != ?
                  AND (a.flag IS NULL OR a.flag = 1)
                  AND NOT EXISTS (
                      SELECT 1
                      FROM ordersglobal og
                      INNER JOIN offer_dataf odf ON odf.id = og.idoffer AND odf.bd = {$bd}
                      WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
                        AND og.user_idok = ?
                        AND og.status = 'выполняется'
                  )
                GROUP BY a.city
                ORDER BY a.city COLLATE utf8mb4_unicode_ci";
        $stmt = $conn->prepare($sql);
        if (!$stmt) throw new Exception($conn->error);
        $stmt->bind_param('ss', $useId, $useId);
    } else {
        $sql = "SELECT a.city, COUNT(DISTINCT a.id) AS cnt
                FROM {$mainTable} AS a
                WHERE a.{$mainColumn} = ?
                  AND a.iduser IS NOT NULL
                  AND a.iduser != ?
                  AND (a.flag IS NULL OR a.flag = 1)
                  AND NOT EXISTS (
                      SELECT 1
                      FROM ordersglobal og
                      INNER JOIN offer_dataf odf ON odf.id = og.idoffer AND odf.bd = {$bd}
                      WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
                        AND og.user_idok = ?
                        AND og.status = 'выполняется'
                  )
                GROUP BY a.city
                ORDER BY a.city COLLATE utf8mb4_unicode_ci";
        $stmt = $conn->prepare($sql);
        if (!$stmt) throw new Exception($conn->error);
        $stmt->bind_param('sss', $namex, $useId, $useId);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    $rows = $result->fetch_all(MYSQLI_ASSOC);

    // Проверка наличия городов
    if (empty($rows)) {
        $rows[] = ['city' => 'В этом разделе ещё нет городов с объявлениями', 'cnt' => 0];
    }

    // Ответ клиенту
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