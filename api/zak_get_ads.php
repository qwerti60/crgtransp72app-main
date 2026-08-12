<?php
require __DIR__ . '/load_databd.php';
require_once __DIR__ . '/include/customer_order_deal.php';
$idusers = isset($_GET['idusers']) ? $_GET['idusers'] : '';

// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

/**
 * Число уникальных исполнителей с активным откликом — как на экране
 * «Предложения исполнителей» (list_predloj_na_obj_isp_new.php).
 */
function offerCountSql(string $adIdColumn, int $bd): string
{
    return "(SELECT COUNT(DISTINCT od.iduserp)
        FROM offer_data od
        WHERE od.iduser = {$adIdColumn}
          AND od.bd = {$bd}
          AND (od.status = 0 OR od.status IS NULL)) AS offer";
}

/**
 * Статус сделки по объявлению заказчика (ordersglobal).
 */
function orderStatusSql(string $adIdColumn, int $bd, string $customerIdColumn): string
{
    return crg_sql_customer_ad_order_status($adIdColumn, $bd, $customerIdColumn);
}

/**
 * Объявление неактивно, пока заказ выполняется. После «выполнен» снова принимает отклики.
 */
function isActiveSql(string $adIdColumn, int $bd, string $customerIdColumn): string
{
    return crg_sql_customer_ad_is_active($adIdColumn, $bd, $customerIdColumn);
}

// Обобщенный SQL-запрос с добавлением имени таблицы
$sql = "
SELECT 
    'orders' as table_name,
    1 AS bd,
    o.id, 
    o.maxgruz, 
    o.city, 
    o.startdate, 
    o.enddate, 
    o.city1, 
    o.vidk, 
    o.zagr, 
    o.typepr, 
    o.cena, 
    o.about, 
    o.enddatez, 
    o.img1, 
    o.img2, 
    o.img3, 
    o.img4, 
    o.created_at,
    " . offerCountSql('o.id', 1) . ",
    " . orderStatusSql('o.id', 1, 'o.iduser') . ",
    " . isActiveSql('o.id', 1, 'o.iduser') . "
FROM 
    orders o
WHERE 
    o.iduser = ?
UNION ALL
SELECT 
    'orderst' as table_name,
    2 AS bd,
    ot.id, 
    '',  -- Поле maxgruz отсутствует в таблице orderst
    ot.city, 
    ot.startdate, 
    ot.enddate, 
    '',  -- Поле city1 отсутствует в таблице orderst
    '',  -- Поле vidk отсутствует в таблице orderst
    '',  -- Поле zagr отсутствует в таблице orderst
    '',  -- Поле typepr отсутствует в таблице orderst
    ot.cena, 
    ot.about, 
    ot.enddatez, 
    ot.img1, 
    ot.img2, 
    ot.img3, 
    ot.img4, 
    ot.created_at,
    " . offerCountSql('ot.id', 2) . ",
    " . orderStatusSql('ot.id', 2, 'ot.iduser') . ",
    " . isActiveSql('ot.id', 2, 'ot.iduser') . "
FROM 
    orderst ot
WHERE 
    ot.iduser = ?
UNION ALL
SELECT 
    'ordersg' as table_name,
    3 AS bd,
    og.id, 
    '',  -- Поле maxgruz отсутствует в таблице ordersg
    og.city, 
    og.startdate, 
    og.enddate, 
    '',  -- Поле city1 отсутствует в таблице ordersg
    '',  -- Поле vidk отсутствует в таблице ordersg
    '',  -- Поле zagr отсутствует в таблице ordersg
    '',  -- Поле typepr отсутствует в таблице ordersg
    og.cena, 
    og.about, 
    og.enddatez, 
    og.img1, 
    og.img2, 
    og.img3, 
    og.img4, 
    og.created_at,
    " . offerCountSql('og.id', 3) . ",
    " . orderStatusSql('og.id', 3, 'og.iduser') . ",
    " . isActiveSql('og.id', 3, 'og.iduser') . "
FROM 
    ordersg og
WHERE 
    og.iduser = ?
ORDER BY 
    created_at DESC;";

$stmt = $conn->prepare($sql); // Подготовливаем запрос

if (!$stmt) {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка подготовки запроса: ' . $conn->error]);
    $conn->close();
    exit;
}

$stmt->bind_param("sss", $idusers, $idusers, $idusers); // Передаваем один раз переменную трижды
$stmt->execute();                     // Выполняем подготовленный запрос
$result = $stmt->get_result();        // Получаем результат выборки

$fetchData = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Преобразуем binary-данные изображений в Base64
        $row['img1'] = $row['img1'] !== null ? base64_encode($row['img1']) : null;
        $row['img2'] = $row['img2'] !== null ? base64_encode($row['img2']) : null;
        $row['img3'] = $row['img3'] !== null ? base64_encode($row['img3']) : null;
        $row['img4'] = $row['img4'] !== null ? base64_encode($row['img4']) : null;

        $fetchData[] = $row;
    }
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($fetchData, JSON_UNESCAPED_UNICODE);

// Закрываем соединение
$stmt->close();
$conn->close();
?>