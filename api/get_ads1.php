<?
include 'databd.php';
$nameImg = isset($_GET['nameImg']) ? $_GET['nameImg'] : '';
$bd = isset($_GET['bd']) ? $_GET['bd'] : '';
// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

if($bd==1)$sql = "SELECT id, iduser, city, marka, godv, maxgruz, dkuzov, shkuzov, vidk, cenahaurs, cenasmena, cenakm, img1, img2, img3, img4, flag FROM add_ob_gp WHERE id";
if($bd==2)$sql = "SELECT id, iduser, city, vidt, cenahaurs, cenasmena, cenakm, img1, img2, img3, img4, flag FROM add_ob_vidt WHERE id";
$result = $conn->query($sql);

$entries = array();

$fetchData = [];
// Этот блок кода должен начать отправку данных
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Код для обработки результата
        $row['img1'] = $row['img1'] !== null ? base64_encode($row['img1']) : null;
        $row['img2'] = $row['img2'] !== null ? base64_encode($row['img2']) : null;
        $row['img3'] = $row['img3'] !== null ? base64_encode($row['img3']) : null;
        $row['img4'] = $row['img4'] !== null ? base64_encode($row['img4']) : null;

        $fetchData[] = $row;
    }

// Устанавливаем заголовок Content-Type для отправки JSON
header('Content-Type: application/json');
    echo json_encode($fetchData);
} else {
    echo json_encode([]);
}
// Закрываем подключение
$conn->close();
?>