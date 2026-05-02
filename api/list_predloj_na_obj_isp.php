<?php
include 'databd.php'; // Предположительно файл databd.php содержит настройки подключения к БД

// Получаем GET-параметры
$nameImg = isset($_GET['nameImg']) && is_numeric($_GET['nameImg']) ? (int) $_GET['nameImg'] : null;
$bd = isset($_GET['bd']) && is_numeric($_GET['bd']) ? (int) $_GET['bd'] : null;
$debug = isset($_GET['debug']) && $_GET['debug'] === '1';

// Проверка наличия обязательных параметров
if ($nameImg === null) {
    http_response_code(400); // Код состояния HTTP 400 — некорректный запрос
    exit(json_encode(['error' => 'Параметр nameImg обязателен']));
}

// Соединение с базой данных
$conn = new mysqli($host, $username, $password, $dbname);
$conn->set_charset("utf8");

// Проверка успешности подключения
if ($conn->connect_error) {
    die("Ошибка подключения к базе данных: " . $conn->connect_error);
}

// Формирование SQL-запроса.
// Важно: не фильтруем через ordersglobal, иначе часть предложений может пропадать.
$sql = "
    SELECT od.id, od.iduser, od.bd, od.cena, od.about, od.iduserp,
           u.fotouser, u.firstName, u.lastName, u.middleName, u.city, u.phone,
           u.namefirm, u.innStr, u.ogrnStr, u.kppStr
    FROM offer_data od
    INNER JOIN users u ON od.iduserp = u.idusers
    WHERE od.iduser = ?
      AND (od.status = 0 OR od.status IS NULL)
";
$sql .= " ORDER BY od.id DESC ";

// Подготовленный SQL-запрос с параметрами для предотвращения инъекций
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $nameImg);
$stmt->execute();

// Выполнение запроса и получение результата
$result = $stmt->get_result();

// Массив для хранения итоговых данных
$data = array();

// Обработка строк результата
while ($row = $result->fetch_assoc()) {
    // Если фотография пользователя существует, преобразуем её в Base64
    if (!empty($row['fotouser'])) {
        $row['fotouser'] = base64_encode($row['fotouser']);
    }
    
    // Добавление обработанной строки в массив данных
    $data[] = $row;
}

// Заголовок ответа для передачи JSON-данных
header('Content-Type: application/json');

if ($debug) {
    $diag = [
        'request' => [
            'nameImg' => $nameImg,
            'bd' => $bd,
        ],
        'sql' => $sql,
        'rows_returned' => count($data),
        'counts' => [],
    ];

    // Диагностика: сколько всего записей в offer_data на этот iduser.
    $countStmt = $conn->prepare("SELECT COUNT(*) AS cnt FROM offer_data WHERE iduser = ?");
    $countStmt->bind_param("i", $nameImg);
    $countStmt->execute();
    $countResult = $countStmt->get_result()->fetch_assoc();
    $diag['counts']['offer_data_by_iduser'] = (int) ($countResult['cnt'] ?? 0);

    // Диагностика: активные/неактивные записи.
    $statusStmt = $conn->prepare("
        SELECT
            SUM(CASE WHEN status = 0 OR status IS NULL THEN 1 ELSE 0 END) AS active_or_null,
            SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS closed
        FROM offer_data
        WHERE iduser = ?
    ");
    $statusStmt->bind_param("i", $nameImg);
    $statusStmt->execute();
    $statusResult = $statusStmt->get_result()->fetch_assoc();
    $diag['counts']['active_or_null'] = (int) ($statusResult['active_or_null'] ?? 0);
    $diag['counts']['closed'] = (int) ($statusResult['closed'] ?? 0);

    echo json_encode([
        'ok' => true,
        'debug' => $diag,
        'data' => $data,
    ]);
} else {
    // Обычный режим: экран ожидает именно массив
    echo json_encode($data);
}

// Закрытие соединения с базой данных
$conn->close();
?>