<?php
$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db   = "u2395188_apps";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die('Connection failed: ' . $conn->connect_error);
}
$conn->set_charset("utf8");

/* данные из POST */
$id         = $_POST['id'];       // ← id записи, которую нужно обновить
$iduser     = $_POST['iduser'];
$city       = $_POST['city'];
$vidt       = $_POST['vidt'];
$cenahaurs  = $_POST['cenahaurs'];
$cenasmena  = $_POST['cenasmena'];
$cenakm     = $_POST['cenakm'];

/* изображения (могут быть NULL, если не загружены) */
$img1    = isset($_FILES['img1']['tmp_name'])    ? file_get_contents($_FILES['img1']['tmp_name'])    : NULL;
$img2    = isset($_FILES['img2']['tmp_name'])    ? file_get_contents($_FILES['img2']['tmp_name'])    : NULL;
$img3    = isset($_FILES['img3']['tmp_name'])    ? file_get_contents($_FILES['img3']['tmp_name'])    : NULL;
$img4    = isset($_FILES['img4']['tmp_name'])    ? file_get_contents($_FILES['img4']['tmp_name'])    : NULL;

$imgDoc1 = isset($_FILES['imgDoc1']['tmp_name']) ? file_get_contents($_FILES['imgDoc1']['tmp_name']) : NULL;
$imgDoc2 = isset($_FILES['imgDoc2']['tmp_name']) ? file_get_contents($_FILES['imgDoc2']['tmp_name']) : NULL;
$imgDoc3 = isset($_FILES['imgDoc3']['tmp_name']) ? file_get_contents($_FILES['imgDoc3']['tmp_name']) : NULL;
$imgDoc4 = isset($_FILES['imgDoc4']['tmp_name']) ? file_get_contents($_FILES['imgDoc4']['tmp_name']) : NULL;

/* подготовка запроса на обновление */
$sql = "UPDATE add_ob_vidt 
        SET iduser    = ?, 
            city      = ?, 
            vidt      = ?, 
            cenahaurs = ?, 
            cenasmena = ?, 
            cenakm    = ?, 
            img1      = ?, 
            img2      = ?, 
            img3      = ?, 
            img4      = ?, 
            imgdoc1   = ?, 
            imgdoc2   = ?, 
            imgdoc3   = ?, 
            imgdoc4   = ?
        WHERE id = ?";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    die('Prepare failed: ' . $conn->error);
}

/* 
   Типы:
   i – integer (iduser, id)
   s – string / blob (остальное)
*/
$stmt->bind_param(
    "isssssssssssssi",
    $iduser,
    $city,
    $vidt,
    $cenahaurs,
    $cenasmena,
    $cenakm,
    $img1,
    $img2,
    $img3,
    $img4,
    $imgDoc1,
    $imgDoc2,
    $imgDoc3,
    $imgDoc4,
    $id               // условие WHERE id = ?
);

if ($stmt->execute()) {
    echo "Record with id=$id updated successfully";
} else {
    echo "Error: " . $stmt->error;
}

$stmt->close();
$conn->close();
?>