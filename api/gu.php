<?
// Подключение к базе данных
require __DIR__ . '/load_databd.php';
$user = $username;
$pass = $password;
$charset = 'utf8';

$dsn = "mysql:host=$host;dbname=$dbname;charset=$charset";
$options = [
PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
PDO::ATTR_EMULATE_PREPARES => false,
];
try {
$pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
throw new \PDOException($e->getMessage(), (int)$e->getCode());
}

// Получение id пользователя из запроса
$idUser = $_GET['idusers'];

// Подготовка и выполнение запроса
$sql = "SELECT fotouser, firstName, lastName, middleName, city, phone, email FROM users WHERE idusers = ?";
$stmt = $pdo->prepare($sql);
$stmt->execute([$idUser]);
$user = $stmt->fetch();

// Преобразование BLOB в base64
if ($user && $user['fotouser']) {
$user['fotouser'] = base64_encode($user['fotouser']);
}

// Отправка данных в формате JSON
header('Content-Type: application/json');
echo json_encode($user);
?>