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

/* Приём данных из формы */
$city = $_POST['city'];
$marka = $_POST['marka'];
$godv = $_POST['godv'];
$maxgruz = $_POST['maxgruz'];
$dkuzov = $_POST['dkuzov'];
$shkuzov = $_POST['shkuzov'];
$vidk = $_POST['vidk'];
$cenahaurs = $_POST['cenahaurs'];
$cenasmena = $_POST['cenasmena'];
$cenakm = $_POST['cenakm'];
$iduser = $_POST['iduser'];
$id = $_POST['id']; // id строки, которую нужно обновить

/* Изображения (можно оставить логику как была) */
$img1 = $_FILES['img1']['tmp_name'] ? file_get_contents($_FILES['img1']['tmp_name']) : NULL;
$img2 = $_FILES['img2']['tmp_name'] ? file_get_contents($_FILES['img2']['tmp_name']) : NULL;
$img3 = $_FILES['img3']['tmp_name'] ? file_get_contents($_FILES['img3']['tmp_name']) : NULL;
$img4 = $_FILES['img4']['tmp_name'] ? file_get_contents($_FILES['img4']['tmp_name']) : NULL;
$imgDoc1 = $_FILES['imgDoc1']['tmp_name'] ? file_get_contents($_FILES['imgDoc1']['tmp_name']) : NULL;
$imgDoc2 = $_FILES['imgDoc2']['tmp_name'] ? file_get_contents($_FILES['imgDoc2']['tmp_name']) : NULL;
$imgDoc3 = $_FILES['imgDoc3']['tmp_name'] ? file_get_contents($_FILES['imgDoc3']['tmp_name']) : NULL;
$imgDoc4 = $_FILES['imgDoc4']['tmp_name'] ? file_get_contents($_FILES['imgDoc4']['tmp_name']) : NULL;

/* Подготовленный запрос на UPDATE */
$sql = "UPDATE add_ob_gp SET
iduser = ?,
city = ?,
marka = ?,
godv = ?,
maxgruz = ?,
dkuzov = ?,
shkuzov = ?,
vidk = ?,
cenahaurs = ?,
cenasmena = ?,
cenakm = ?,
img1 = ?,
img2 = ?,
img3 = ?,
img4 = ?,
imgdoc1 = ?,
imgdoc2 = ?,
imgdoc3 = ?,
imgdoc4 = ?
WHERE id = ?";

$stmt = $conn->prepare($sql);

$stmt->bind_param(
"issisiissssssssssssi",
$iduser,
$city,
$marka,
$godv,
$maxgruz,
$dkuzov,
$shkuzov,
$vidk,
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
$id // <-- последнее поле для WHERE id = ?
);

if ($stmt->execute()) {
echo "Record updated successfully";
} else {
echo "Error: " . $stmt->error;
}

$stmt->close();
$conn->close();
?>