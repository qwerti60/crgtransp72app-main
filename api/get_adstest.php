<?php
include 'databd.php';

// Получаем id пользователя
$idusers = isset($_GET['idusers']) && is_numeric($_GET['idusers']) ? intval($_GET['idusers']) : 0;

// Подключаемся к БД
$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    die('Ошибка подключения: ' . $conn->connect_error);
}
$conn->set_charset('utf8');

$sql = "
SELECT gp.id,
       gp.city,
       COALESCE(gp.marka,'')   AS marka,
       COALESCE(gp.godv,'')    AS godv,
       COALESCE(gp.maxgruz,'') AS maxgruz,
       COALESCE(gp.dkuzov,'')  AS dkuzov,
       COALESCE(gp.shkuzov,'') AS shkuzov,
       COALESCE(gp.vidk,'')    AS vidk,
       gp.cenahaurs,
       gp.cenasmena,
       gp.cenakm,
       gp.img1, gp.img2, gp.img3, gp.img4,
       gp.flag,
       gp.created_at,
       GREATEST(
           (SELECT COUNT(*) FROM offer_data  od WHERE od.iduser = gp.id) -
           (SELECT COUNT(*) FROM ordersglobal og WHERE og.order_id = gp.id
                                                   AND og.status IN ('выполнен','отменен')), 0
       ) AS offerf,
       'add_ob_gp'  AS tableName
FROM  add_ob_gp gp
WHERE gp.iduser = ?

UNION ALL
SELECT vidt.id,
       vidt.city, 
       ''  AS marka, '' AS godv, '' AS maxgruz,
       ''  AS dkuzov, '' AS shkuzov, vidt.vidt,      -- Добавили сюда поле vidt
       vidt.cenahaurs,
       vidt.cenasmena,
       vidt.cenakm,
       vidt.img1, vidt.img2, vidt.img3, vidt.img4,
       vidt.flag,
       vidt.created_at,
       GREATEST(
           (SELECT COUNT(*) FROM offer_data  od WHERE od.iduser = vidt.id) -
           (SELECT COUNT(*) FROM ordersglobal og WHERE og.order_id = vidt.id
                                                   AND og.status IN ('выполнен','отменен')), 0
       ) AS offerf,
       'add_ob_vidt' AS tableName
FROM add_ob_vidt vidt
WHERE vidt.iduser = ?

UNION ALL
SELECT gr.id,
       gr.city,
       ''  AS marka, '' AS godv, '' AS maxgruz,
       ''  AS dkuzov, '' AS shkuzov, '' AS vidk,
       gr.cenahaurs,
       gr.cenasmena,
       gr.cenakm,
       gr.img1, gr.img2, gr.img3, gr.img4,
       gr.flag,
       gr.created_at,
       GREATEST(
           (SELECT COUNT(*) FROM offer_data  od WHERE od.iduser = gr.id) -
           (SELECT COUNT(*) FROM ordersglobal og WHERE og.order_id = gr.id
                                                   AND og.status IN ('выполнен','отменен')), 0
       ) AS offerf,
       'add_ob_gr'  AS tableName
FROM add_ob_gr gr
WHERE gr.iduser = ?

ORDER BY created_at DESC
";

// Выполняем подготовленный запрос
$stmt = $conn->prepare($sql);
if (!$stmt) {
    die('Ошибка подготовки запроса: ' . $conn->error);
}

// Передаем ID пользователя трижды, так как каждая таблица требует своего условия фильтра
$stmt->bind_param('iii', $idusers, $idusers, $idusers);
$stmt->execute();
$result = $stmt->get_result();

// Формируем итоговые данные
$fetchData = [];
while ($row = $result->fetch_assoc()) {
    // Преобразуем бинарные изображения в base64
    foreach (['img1', 'img2', 'img3', 'img4'] as $img) {
        if (!empty($row[$img])) { // Проверяем наличие изображений перед конвертацией
            $row[$img] = base64_encode($row[$img]);
        } else {
            $row[$img] = null;
        }
    }
    $fetchData[] = $row;
}

// Возвращаем JSON-данные
header('Content-Type: application/json');
echo json_encode($fetchData);

// Закрываем соединение
$stmt->close();
$conn->close();
?>