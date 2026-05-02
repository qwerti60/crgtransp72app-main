<?
// Обычно токен выдается с использованием каких-либо фреймворков или библиотек,
// здесь просто иллюстрация API.

header("Content-Type: application/json");
include 'databd.php';

// Create a new MySQLi connection
$conn = new mysqli($host, $username, $password, $dbname);

$email = $_POST['email'];
$password = $_POST['password'];

$response = array();
$response['success'] = false; // Устанавливаем false по умолчанию

if ($stmt = $conn->prepare('SELECT idusers, rollNum, statNum, password, flag FROM users WHERE email = ?')) { // Исправление $con на $conn
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $stmt->store_result();

    if ($stmt->num_rows > 0) {
        $stmt->bind_result($idusers, $rollNum, $statNum, $hashed_password, $flag);
        $stmt->fetch();

        if (password_verify($password, $hashed_password)) {
            // Проверяем rollNum и flag
            if (($rollNum == 2 || $rollNum == 3) && $flag == 0) {
                $response['message'] = "Данные пользователя еще на проверке";
            } else {
                $response['success'] = true; // Аутентификация успешна
                $response['rollNum'] = $rollNum;
                $response['statNum'] = $statNum;
            }
        } else {
            $response['message'] = "Неверный пароль".$password;
        }
    } else {
        $response['message'] = "Пользователь не найден ".$email;
    }

    $stmt->close();
} else {
    $response['message'] = "Ошибка сервера";
}

echo json_encode($response);
$conn->close();
?>