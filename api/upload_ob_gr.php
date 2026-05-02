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

/* Данные из формы */
$id        = $_POST['id'];       // id строки, которую нужно обновить
$iduser    = $_POST['iduser'];
$city      = $_POST['city'];
$cenahaurs = $_POST['cenahaurs'];
$cenasmena = $_POST['cenasmena'];
$cenakm    = $_POST['cenakm'];

/* Файлы (если не передан — оставляем NULL) */
$img1 = !empty($_FILES['img1']['tmp_name'])      ? file_get_contents($_FILES['img1']['tmp_name'])      : NULL;
$img2 = !empty($_FILES['img2']['tmp_name'])      ? file_get_contents($_FILES['img2']['tmp_name'])      : NULL;
$img3 = !empty($_FILES['img3']['tmp_name'])      ? file_get_contents($_FILES['img3']['tmp_name'])      : NULL;
$img4 = !empty($_FILES['img4']['tmp_name'])      ? file_get_contents($_FILES['img4']['tmp_name'])      : NULL;

$imgDoc1 = !empty($_FILES['imgDoc1']['tmp_name'])? file_get_contents($_FILES['imgDoc1']['tmp_name'])    : NULL;
$imgDoc2 = !empty($_FILES['imgDoc2']['tmp_name'])? file_get_contents($_FILES['imgDoc2']['tmp_name'])    : NULL;
$imgDoc3 = !empty($_FILES['imgDoc3']['tmp_name'])? file_get_contents($_FILES['imgDoc3']['tmp_name'])    : NULL;
$imgDoc4 = !empty($_FILES['imgDoc4']['tmp_name'])? file_get_contents($_FILES['imgDoc4']['tmp_name'])    : NULL;

/* UPDATE вместо INSERT */
$sql = "UPDATE add_ob_gr 
        SET  iduser     = ?,
             city       = ?,
             cenahaurs  = ?,
             cenasmena  = ?,
             cenakm     = ?,
             img1       = ?,
             img2       = ?,
             img3       = ?,
             img4       = ?,
             imgdoc1    = ?,
             imgdoc2    = ?,
             imgdoc3    = ?,
             imgdoc4    = ?
        WHERE id = ?";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    die('Prepare failed: ' . $conn->error);
}

/* 
 * Типы:
 *  i ‒ integer (iduser, id),
 *  s ‒ string (city, cenahaurs...),
 *  b ‒ blob  (изображения). 
 * Можно оставить все как 's', но корректнее для BLOB ставить 'b'.
 */
$stmt->bind_param(
    "issssssssssssi",
    $iduser,   // i
    $city,     // s
    $cenahaurs,// s
    $cenasmena,// s
    $cenakm,   // s
    $img1,     // s/b
    $img2,     // s/b
    $img3,     // s/b
    $img4,     // s/b
    $imgDoc1,  // s/b
    $imgDoc2,  // s/b
    $imgDoc3,  // s/b
    $imgDoc4,  // s/b
    $id        // i (WHERE id = ?)
);

if ($stmt->execute()) {
    echo "Record updated successfully";
} else {
    echo "Error: " . $stmt->error;
}

$stmt->close();
$conn->close();
?>