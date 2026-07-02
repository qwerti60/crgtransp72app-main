<?php
include 'databd.php';

$idusers = $_GET['idusers'] ?? '';
$bd      = $_GET['bd']      ?? '';

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    die('Ошибка подключения: ' . $conn->connect_error);
}
$conn->set_charset('utf8');

/* -------------------------------------------------
 * универсальный кусок для расчёта offerf
 * ------------------------------------------------- */
$offerf =
" ( SELECT COUNT(DISTINCT od.iduserp)
      FROM offer_dataf od
     WHERE od.iduser = a.id
       AND od.bd = " . (int) $bd . "
       AND od.isp = 0
  ) AS offerf";

/* -------------------------------------------------
 * формируем основной запрос
 * ------------------------------------------------- */
if ($bd == 1) {
    $sql = "
      SELECT a.id, a.city, a.marka, a.godv, a.maxgruz,
             a.dkuzov, a.shkuzov, a.vidk,
             a.cenahaurs, a.cenasmena, a.cenakm,
             a.img1, a.img2, a.img3, a.img4,
             a.flag, a.created_at,
             $offerf
        FROM add_ob_gp a
       WHERE a.iduser = ?
       ORDER BY a.created_at DESC";
} elseif ($bd == 2) {
    $sql = "
      SELECT a.id, a.city, a.vidt,
             a.cenahaurs, a.cenasmena, a.cenakm,
             a.img1, a.img2, a.img3, a.img4,
             a.flag, a.created_at,
             $offerf
        FROM add_ob_vidt a
       WHERE a.iduser = ?
       ORDER BY a.created_at DESC";
} elseif ($bd == 3) {
    $sql = "
      SELECT a.id, a.city,
             a.cenahaurs, a.cenasmena, a.cenakm,
             a.img1, a.img2, a.img3, a.img4,
             a.flag, a.created_at,
             $offerf
        FROM add_ob_gr a
       WHERE a.iduser = ?
       ORDER BY a.created_at DESC";
} else {
    die('Неверный параметр bd');
}

/* -------------------------------------------------
 * выполняем запрос
 * ------------------------------------------------- */
$stmt = $conn->prepare($sql);
if (!$stmt) {
    die('Ошибка подготовки запроса: ' . $conn->error);
}

$stmt->bind_param('i', $idusers);
$stmt->execute();
$result = $stmt->get_result();

$fetchData = [];
while ($row = $result->fetch_assoc()) {
    // преобразуем бинарные изображения в base64
    foreach (['img1','img2','img3','img4'] as $img) {
        $row[$img] = $row[$img] !== null ? base64_encode($row[$img]) : null;
    }
    $fetchData[] = $row;
}

header('Content-Type: application/json');
echo json_encode($fetchData);

$stmt->close();
$conn->close();
?> 