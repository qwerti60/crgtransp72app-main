<?
header('Content-Type: application/json; charset=UTF-8');

include 'databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->exec("SET NAMES 'utf8mb4'");
    
    $data = json_decode(file_get_contents('php://input'), true);
$email = $data['email'];
$pass = $data['password'];
$phone = $data['phone'];

$rollNum = $data['rollNum'];
$statNum = $data['statNum'];
$firstName = $data['firstName'];
$lastName = $data['lastName'];
$middleName = $data['middleName'];
$city = $data['city'];

// Проверим наличие email или телефона в БД
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = :email OR phone = :phone");
$stmt->execute(['email' => $email, 'phone' => $phone]);
$user = $stmt->fetch();

if ($user) {
echo json_encode(['status' => 'error', 'message' => 'Email или телефон уже зарегистрированы']);
} else {
$stmt = $pdo->prepare("INSERT INTO users (rollNum, statNum, firstName, lastName, middleName, city, phone, email, password) VALUES (:rollNum, :statNum, :firstName, :lastName, :middleName, :city, :phone, :email, :password)");
$stmt->execute([
'rollNum' => $rollNum,
'statNum' => $statNum,
'firstName' => $firstName,
'lastName' => $lastName,
'middleName' => $middleName,
'city' => $city,
'email' => $email,
'password' => password_hash($pass, PASSWORD_BCRYPT),
'phone' => $phone,
]);

echo json_encode(['status' => 'success', 'message' => 'Регистрация успешна']);
}
} catch (PDOException $e) {
echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}?>
