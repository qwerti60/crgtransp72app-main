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
$city = $_POST['city'];
$vidt = $_POST['vidt'];
$cenahaurs = $_POST['cenahaurs'];
$cenasmena = $_POST['cenasmena'];
$cenakm = $_POST['cenakm'];

// Примерное считывание и обработка изображений
$img1 = $_FILES['img1']['tmp_name'] ? file_get_contents($_FILES['img1']['tmp_name']) : NULL;
$img2 = $_FILES['img2']['tmp_name'] ? file_get_contents($_FILES['img2']['tmp_name']) : NULL;
$img3 = $_FILES['img3']['tmp_name'] ? file_get_contents($_FILES['img3']['tmp_name']) : NULL;
$img4 = $_FILES['img4']['tmp_name'] ? file_get_contents($_FILES['img4']['tmp_name']) : NULL;

$imgDoc1 = $_FILES['imgDoc1']['tmp_name'] ? file_get_contents($_FILES['imgDoc1']['tmp_name']) : NULL;
$imgDoc2 = $_FILES['imgDoc2']['tmp_name'] ? file_get_contents($_FILES['imgDoc2']['tmp_name']) : NULL;
$imgDoc3 = $_FILES['imgDoc3']['tmp_name'] ? file_get_contents($_FILES['imgDoc3']['tmp_name']) : NULL;
$imgDoc4 = $_FILES['imgDoc4']['tmp_name'] ? file_get_contents($_FILES['imgDoc4']['tmp_name']) : NULL;

$stmt = $conn->prepare("INSERT INTO add_ob_vidt (iduser, city, vidt, cenahaurs, cenasmena, cenakm, img1, img2, img3, img4, imgdoc1, imgdoc2, imgdoc3, imgdoc4) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("isssssssssssss", $iduser, $city, $vidt, $cenahaurs, $cenasmena, $cenakm, $img1, $img2, $img3, $img4, $imgDoc1, $imgDoc2, $imgDoc3, $imgDoc4);

if ($stmt->execute()) {
echo "New record created successfully";
} else {
echo "Error: " . $stmt->error;
}

$conn->close();
?>
