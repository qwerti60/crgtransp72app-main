<?php
$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db = "u2395188_apps";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die('Connection failed: ' . $conn->connect_error);
}
$conn->set_charset("utf8");

$id = $_POST['id'];
$iduser = $_POST['iduser'];
$maxgruz = $_POST['maxgruz'];
$city = $_POST['city'];
$startdate = $_POST['startdate'];
$enddate = $_POST['enddate'];
$city1 = $_POST['city1'];
$vidk = $_POST['vidk'];
$zagr = $_POST['zagr'];
$typeper = $_POST['typeper'];
$cena = $_POST['cena'];
$about = $_POST['about'];
$enddatez = $_POST['enddatez'];

// Обработка изображений
$img1 = isset($_FILES['img1']['tmp_name']) && !empty($_FILES['img1']['tmp_name']) ? file_get_contents($_FILES['img1']['tmp_name']) : NULL;
$img2 = isset($_FILES['img2']['tmp_name']) && !empty($_FILES['img2']['tmp_name']) ? file_get_contents($_FILES['img2']['tmp_name']) : NULL;
$img3 = isset($_FILES['img3']['tmp_name']) && !empty($_FILES['img3']['tmp_name']) ? file_get_contents($_FILES['img3']['tmp_name']) : NULL;
$img4 = isset($_FILES['img4']['tmp_name']) && !empty($_FILES['img4']['tmp_name']) ? file_get_contents($_FILES['img4']['tmp_name']) : NULL;

$stmt = $conn->prepare("UPDATE orders SET iduser=?, maxgruz=?, city=?, startdate=?, enddate=?, city1=?, vidk=?, zagr=?, typepr=?, cena=?, about=?, enddatez=?, img1=?, img2=?, img3=?, img4=? WHERE id=?");
$stmt->bind_param("isssssssssssssssi", $iduser, $maxgruz, $city, $startdate, $enddate, $city1, $vidk, $zagr, $typeper, $cena, $about, $enddatez, $img1, $img2, $img3, $img4, $id);

if ($stmt->execute()) {
    echo "Record updated successfully";
} else {
    echo "Error updating record: " . $stmt->error;
}

$conn->close();
?>