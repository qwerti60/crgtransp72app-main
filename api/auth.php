<?
header('Content-Type: application/json');
require_once '/var/www/u2395188/data/vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

include 'databd.php';

// Create a new MySQLi connection
$conn = new mysqli($host, $username, $password, $dbname);

// Получение данных из запроса
$data = json_decode(file_get_contents("php://input"), true);

if (isset($_POST['email']) && isset($_POST['password'])) {
    $email = $_POST['email'];
    $password = $_POST['password'];
    // Your authentication logic here

// Поиск пользователя в БД
$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

// Проверка пароля (здесь без хеширования для упрощения)
if ($user && $password == $user['password']) {
// Проверка rollNum и flag
if (in_array($user['rollNum'], [2, 3]) && $user['flag'] == 0) {
echo json_encode(["message" => "Данные пользователя еще на проверке"]);
} else {
// Генерация JWT
$key = "16082024";
$payload = [
"iss" => "ivnovav.ru", // Издатель токена
"aud" => "ivnovav.ru", // Потребитель токена
"iat" => time(), // Время, когда токен был выпущен
"nbf" => time(), // Время, до которого токен не может быть принят
"exp" => time() + 3600, // Время истечения срока действия токен
"data" => [
"idusers" => $user['idusers'],
"email" => $user['email'],
"rollNum" => $user['rollNum'],
"statNum" => $user['statNum']
]
];

$jwt = JWT::encode($payload, $key);
echo json_encode(["token" => $jwt]);
}
} else {
echo json_encode(["message" => "Неверный логин или пароль"]);
}
    
} else {
echo json_encode(["message" => "Не получен логин или пароль"]);
}

?>