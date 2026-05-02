<?
$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db = "u2395188_apps";

$conn = new PDO("mysql:host=$host;dbname=$db", $user, $pass);

// Получение входных данных
$idusers = $_GET['idusers'];
$id = $_GET['id'];
$bd = $_GET['bd'];

// Подготовка и выполнение запроса на проверку наличия лайка
$stmt = $conn->prepare("SELECT COUNT(*) FROM likes WHERE idusers = :idusers AND id = :id AND bd = :bd");
$stmt->execute(['idusers' => $idusers, 'id' => $id, 'bd' => $bd]);
$count = $stmt->fetchColumn();

// Отправка результата
echo json_encode(['success' => $count > 0 ? true : false]);
?>