<?
$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db = "u2395188_apps";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
die('Connection failed: ' . $conn->connect_error);
}
$conn->set_charset("utf8");
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

// Примерное считывание и обработка изображений
$img1 = $_FILES['img1']['tmp_name'] ? file_get_contents($_FILES['img1']['tmp_name']) : NULL;
$img2 = $_FILES['img2']['tmp_name'] ? file_get_contents($_FILES['img2']['tmp_name']) : NULL;
$img3 = $_FILES['img3']['tmp_name'] ? file_get_contents($_FILES['img3']['tmp_name']) : NULL;
$img4 = $_FILES['img4']['tmp_name'] ? file_get_contents($_FILES['img4']['tmp_name']) : NULL;


$stmt = $conn->prepare("INSERT INTO orders (iduser, maxgruz, city, startdate, enddate, city1, vidk, zagr, typepr, cena, about, enddatez, img1, img2, img3, img4) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("isssssssssssssss", $iduser, $maxgruz, $city, $startdate, $enddate, $city1, $vidk, $zagr, $typeper, $cena, $about, $enddatez, $img1, $img2, $img3, $img4);

//$stmt->bind_param("issisiissssssssssss", $iduser, $city, $marka, $godv, $maxgruz, $dkuzov, $shkuzov, $vidk, $cenahaurs, $cenasmena, $cenakm, $img1, $img2, $img3, $img4, $imgdoc1, $imgdoc2, $imgdoc3, $imgdoc4);

if ($stmt->execute()) {
echo "New record created successfully";
} else {
echo "Error: " . $stmt->error;
}

$conn->close();
?>
