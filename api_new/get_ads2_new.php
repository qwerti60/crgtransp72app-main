<?php
require_once __DIR__ . '/../api/databd.php';

$nameImg = isset($_GET['nameImg']) ? $_GET['nameImg'] : '';
$city    = isset($_GET['city']) ? $_GET['city'] : '';
$useId   = isset($_GET['usersid']) ? $_GET['usersid'] : '';
if ($useId === '' && isset($_GET['useId'])) {
    $useId = $_GET['useId'];
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");

$table = null;
$condition = "";

$sqlCheckDdObGP = "SELECT 1 FROM add_ob_gp WHERE maxgruz = ? LIMIT 1";
$stmt = $conn->prepare($sqlCheckDdObGP);
$stmt->bind_param("s", $nameImg);
$stmt->execute();
$resultDdObGP = $stmt->get_result();
if ($resultDdObGP && $resultDdObGP->num_rows > 0) {
    $table = 'add_ob_gp';
    $condition = "AND a.maxgruz = ?";
} else {
    $sqlCheckAddObVidt = "SELECT 1 FROM add_ob_vidt WHERE vidt = ? LIMIT 1";
    $stmt = $conn->prepare($sqlCheckAddObVidt);
    $stmt->bind_param("s", $nameImg);
    $stmt->execute();
    $resultAddObVidt = $stmt->get_result();

    if ($resultAddObVidt && $resultAddObVidt->num_rows > 0) {
        $table = 'add_ob_vidt';
        $condition = "AND a.vidt = ?";
    } else {
        $sqlCheckAddObGr = "SELECT 1 FROM add_ob_gr LIMIT 1";
        $resultAddObGr = $conn->query($sqlCheckAddObGr);
        if ($resultAddObGr && $resultAddObGr->num_rows > 0) {
            $table = 'add_ob_gr';
            $condition = "";
        }
    }
}

if (!$table) {
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
           COUNT(r.user_id) AS reviewsCount,
           COUNT(r.user_id) AS review_count,
           COALESCE(AVG(r.rating), 0) AS avg_rating,
           CASE
               WHEN EXISTS(
                   SELECT 1
                   FROM likes1 l
                   WHERE l.idusers = u.idusers
                     AND l.id = a.id
                     AND l.usersid = ?
               ) THEN 'true'
               ELSE 'false'
           END AS success
    FROM {$table} AS a
    LEFT JOIN users AS u ON a.iduser = u.idusers
    LEFT JOIN reviewsisp AS r ON u.idusers = r.user_id
    LEFT JOIN offer_data od ON od.id = a.id AND od.isp = 1
    WHERE a.iduser IS NOT NULL
      AND a.iduser != ?
      AND a.city = ?
      {$condition}
      AND od.id IS NULL
    GROUP BY a.id, u.idusers
    ORDER BY a.id DESC
";

if ($condition !== "") {
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssss", $useId, $useId, $city, $nameImg);
} else {
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sss", $useId, $useId, $city);
}

$stmt->execute();
$result = $stmt->get_result();

$fetchData = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $imgsToEncode = ['img1', 'img2', 'img3', 'img4'];
        foreach ($imgsToEncode as $imgField) {
            if (!empty($row[$imgField])) {
                $row[$imgField] = base64_encode($row[$imgField]);
            }
        }

        foreach (['imgdoc1', 'imgdoc2', 'imgdoc3', 'imgdoc4'] as $doc) {
            unset($row[$doc]);
        }

        if (!empty($row['fotouser'])) {
            $row['fotouser'] = base64_encode($row['fotouser']);
        }

        $fetchData[] = $row;
    }
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($fetchData, JSON_UNESCAPED_UNICODE);

$conn->close();
?>
