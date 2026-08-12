<?php
require __DIR__ . '/load_databd.php';
require_once __DIR__ . '/include/customer_order_deal.php';

$nameImg = isset($_GET['nameImg']) ? $_GET['nameImg'] : '';
$city    = isset($_GET['city']) ? $_GET['city'] : '';
$useId   = isset($_GET['useId']) ? $_GET['useId'] : '';
if ($useId === '' && isset($_GET['usersid'])) {
    $useId = $_GET['usersid'];
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}
$conn->set_charset("utf8");

$currentDate = date('Y-m-d');

$table = null;

$stmt = $conn->prepare("SELECT 1 FROM vidt WHERE name = ? LIMIT 1");
$stmt->bind_param("s", $nameImg);
$stmt->execute();
$resultVidt = $stmt->get_result();
if ($resultVidt && $resultVidt->num_rows > 0) {
    $table = 'orderst';
} else {
    $stmt = $conn->prepare("SELECT 1 FROM vidg WHERE name = ? LIMIT 1");
    $stmt->bind_param("s", $nameImg);
    $stmt->execute();
    $resultVidg = $stmt->get_result();

    if ($resultVidg && $resultVidg->num_rows > 0) {
        $table = 'orders';
    } else {
        $stmt = $conn->prepare("SELECT 1 FROM gruzchik WHERE name = ? LIMIT 1");
        $stmt->bind_param("s", $nameImg);
        $stmt->execute();
        $resultGruzchik = $stmt->get_result();
        if ($resultGruzchik && $resultGruzchik->num_rows > 0) {
            $table = 'ordersg';
        }
    }
}

if (!$table) {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

switch ($table) {
    case 'orderst':
        $bd = 2;
        break;
    case 'orders':
        $bd = 1;
        break;
    case 'ordersg':
        $bd = 3;
        break;
    default:
        echo json_encode([], JSON_UNESCAPED_UNICODE);
        $conn->close();
        exit;
}

$sql = "
    SELECT a.*,
           u.idusers AS idusers,
           u.idusers AS review_user_id,
           u.fotouser,
           u.firstName,
           u.lastName,
           u.middleName,
           u.city AS userCity,
           u.phone,
           u.email,
           COUNT(r.id) AS reviewsCount,
           COALESCE(AVG(r.rating), 0) AS avg_rating,
           CASE
               WHEN EXISTS(
                   SELECT 1
                   FROM likes l
                   WHERE l.idusers = u.idusers
                     AND l.id = a.id
                     AND l.usersid = ?
               ) THEN 'true'
               ELSE 'false'
           END AS success
    FROM {$table} AS a
    INNER JOIN users AS u ON a.iduser = u.idusers
    LEFT JOIN reviews AS r ON u.idusers = r.target_user_id
    WHERE a.iduser IS NOT NULL
      AND a.enddatez >= ?
      AND a.iduser != ?
      AND a.city = ?
      AND NOT EXISTS (
          SELECT 1 FROM offer_data od
          WHERE od.iduser = a.id AND od.bd = {$bd} AND od.isp = 1
            AND (od.status = 0 OR od.status IS NULL)
      )
      AND NOT EXISTS (
          SELECT 1 FROM ordersglobal og
          WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
            AND (og.bd IS NULL OR og.bd = {$bd} OR og.bd = 0)
            AND og.status = 'выполняется'
      )
    GROUP BY a.id, u.idusers
    ORDER BY a.id DESC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ssss", $useId, $currentDate, $useId, $city);
$stmt->execute();
$result = $stmt->get_result();

$fetchData = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $imgsToEncode = ['img1', 'img2', 'img3', 'img4', 'fotouser'];
        foreach ($imgsToEncode as $imgField) {
            if (isset($row[$imgField]) && $row[$imgField] !== null) {
                $row[$imgField] = base64_encode($row[$imgField]);
            }
        }
        $fetchData[] = $row;
    }
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($fetchData, JSON_UNESCAPED_UNICODE);

$conn->close();
?>
