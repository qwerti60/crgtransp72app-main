<?
require __DIR__ . '/load_databd.php';
// Установка соединения с базой данных
$conn = new mysqli($host, $username, $password, $dbname);

// Проверка соединения
if ($conn->connect_error) {
die("Connection failed: " . $conn->connect_error);
}

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
$rollNum = $_POST['rollNum'];
$statNum = $_POST['statNum'];
$firstName = $_POST['firstName'];
$middleName = $_POST['middleName'];
$lastName = $_POST['lastName'];
$city = $_POST['city'];
$phone = $_POST['phone'];
$email = $_POST['email'];
$password = $_POST['password'];
$namefirm = $_POST['namefirm'];
$innStr = $_POST['innStr'];
$ogrnStr = $_POST['ogrnStr'];
$vidt = $_POST['vidt'];
$marka = $_POST['marka'];
$godv = $_POST['godv'];
$maxgruz = $_POST['maxgruz'];
$dkuzov = $_POST['dkuzov'];
$shkuzov = $_POST['shkuzov'];
$vidk = $_POST['vidk'];
$cenahaurs = $_POST['cenahaurs'];
$cenasmena = $_POST['cenasmena'];
$cenakm = $_POST['cenakm'];

// Use prepared statements to prevent SQL injection
$stmt = $conn->prepare("INSERT INTO users (rollNum, statNum, firstName, lastName, middleName, city, phone, email, password, namefirm, innStr, ogrnStr, vidt, marka, godv, maxgruz, dkuzov, shkuzov, vidk, cenahaurs, cenasmena, cenakm) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("ssssssssssssssssssssss", $rollNum, $statNum, $firstName, $lastName, $middleName, $city, $phone, $email, $password, $namefirm, $innStr, $ogrnStr, $vidt, $marka, $godv, $maxgruz, $dkuzov, $shkuzov, $vidk, $cenahaurs, $cenasmena, $cenakm);

if ($stmt->execute()) {
$response['status'] = 'success';
$response['message'] = 'Регистрация успешна';
} else {
$response['status'] = 'error';
$response['message'] = 'Ошибка регистрации';
}

$stmt->close();
$conn->close();
} else {
$response['status'] = 'error';
$response['message'] = 'Invalid request';
}

echo json_encode($response);
?>