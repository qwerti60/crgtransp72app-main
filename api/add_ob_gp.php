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
$cenakm = $_POST['cenakm'];
$iduser = $_POST['iduser'];

// Примерное считывание и обработка изображений
$img1 = $_FILES['img1']['tmp_name'] ? file_get_contents($_FILES['img1']['tmp_name']) : NULL;
$img2 = $_FILES['img2']['tmp_name'] ? file_get_contents($_FILES['img2']['tmp_name']) : NULL;
$img3 = $_FILES['img3']['tmp_name'] ? file_get_contents($_FILES['img3']['tmp_name']) : NULL;
$img4 = $_FILES['img4']['tmp_name'] ? file_get_contents($_FILES['img4']['tmp_name']) : NULL;

$imgDoc1 = $_FILES['imgDoc1']['tmp_name'] ? file_get_contents($_FILES['imgDoc1']['tmp_name']) : NULL;
$imgDoc2 = $_FILES['imgDoc2']['tmp_name'] ? file_get_contents($_FILES['imgDoc2']['tmp_name']) : NULL;
$imgDoc3 = $_FILES['imgDoc3']['tmp_name'] ? file_get_contents($_FILES['imgDoc3']['tmp_name']) : NULL;
$imgDoc4 = $_FILES['imgDoc4']['tmp_name'] ? file_get_contents($_FILES['imgDoc4']['tmp_name']) : NULL;

// Загрузка изображений документов в уникальные файлы
// Предполагая, что $conn - это ваш объект подключения к базе данных.
/*$target_dir = "uploads/";

// Функция для обработки загруженных изображений
function processImageUpload($fieldName) {
    global $target_dir; // Используем глобальную переменную в функции
    if (isset($_FILES[$fieldName]) && $_FILES[$fieldName]['error'] == UPLOAD_ERR_OK) {
        // Проверяем, был ли файл успешно загружен без ошибок
        return $target_dir . uniqid() . basename($_FILES[$fieldName]["name"]);
    } else {
        // Если файл не был загружен или произошла ошибка, возвращаем NULL
        return NULL;
    }
}

// Обрабатываем каждый файл
$imgdoc1 = processImageUpload("imgdoc1");
if ($imgdoc1) {
    move_uploaded_file($_FILES["imgdoc1"]["tmp_name"], $imgdoc1);
}

$imgdoc2 = processImageUpload("imgdoc2");
if ($imgdoc2) {
    move_uploaded_file($_FILES["imgdoc2"]["tmp_name"], $imgdoc2);
}

$imgdoc3 = processImageUpload("imgdoc3");
if ($imgdoc3) {
    move_uploaded_file($_FILES["imgdoc3"]["tmp_name"], $imgdoc3);
}

$imgdoc4 = processImageUpload("imgdoc4");
if ($imgdoc4) {
    move_uploaded_file($_FILES["imgdoc4"]["tmp_name"], $imgdoc4);
}
*/
$stmt = $conn->prepare("INSERT INTO add_ob_gp (iduser, city, marka, godv, maxgruz, dkuzov, shkuzov, vidk, cenahaurs, cenasmena, cenakm, img1, img2, img3, img4, imgdoc1, imgdoc2, imgdoc3, imgdoc4) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("issisiissssssssssss", $iduser, $city, $marka, $godv, $maxgruz, $dkuzov, $shkuzov, $vidk, $cenahaurs, $cenasmena, $cenakm, $img1, $img2, $img3, $img4, $imgDoc1, $imgDoc2, $imgDoc3, $imgDoc4);

if ($stmt->execute()) {
echo "New record created successfully";
} else {
echo "Error: " . $stmt->error;
}

$conn->close();
?>
