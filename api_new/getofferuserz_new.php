<?php
require_once __DIR__ . '/../api/databd.php';

$nameImg = isset($_GET['nameImg']) ? $_GET['nameImg'] : '';
$bd = isset($_GET['bd']) ? $_GET['bd'] : '';
$useId = isset($_GET['useId']) ? $_GET['useId'] : '';

$conn = new mysqli($host, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

$conn->set_charset("utf8mb4");

$currentDate = date('Y-m-d');

switch ($bd) {
    case 1:
        $table = 'orders';
        break;
    case 2:
        $table = 'orderst';
        break;
    case 3:
        $table = 'ordersg';
        break;
    default:
        die("Неверная база данных");
}

$sql = "
    SELECT a.*,
           u.idusers AS idusers,
           u.fotouser,
           u.firstName,
           u.lastName,
           u.middleName,
           u.city AS userCity,
           u.phone,
           u.email,
           COALESCE(AVG(r.rating), 0) AS rating,
           COALESCE(COUNT(r.id), 0) AS reviewsCount,
           CASE
               WHEN EXISTS(
                   SELECT *
                   FROM likes
                   WHERE idusers = u.idusers AND
                         id = a.id AND
                         bd = {$bd}
               ) THEN 'true'
               ELSE 'false'
           END AS success
    FROM {$table} AS a
    INNER JOIN users AS u ON a.iduser = u.idusers
    INNER JOIN offer_dataf AS od ON a.id = od.iduser
    LEFT JOIN reviews r ON u.idusers = r.target_user_id
    WHERE od.bd = {$bd} AND od.iduserp = '{$useId}'
          AND a.enddatez >= '$currentDate'
    GROUP BY a.id, u.idusers
    ORDER BY a.id DESC
";

$result = $conn->query($sql);

$fetchData = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $imgsToEncode = ['img1', 'img2', 'img3', 'img4', 'fotouser'];
        foreach ($imgsToEncode as $imgField) {
            if (isset($row[$imgField])) {
                $row[$imgField] = base64_encode($row[$imgField]);
            }
        }

        $fetchData[] = $row;
    }

    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($fetchData, JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
}

$conn->close();
?>
