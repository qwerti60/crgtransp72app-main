<?
require __DIR__ . '/load_databd.php';
$pass = $password;
$db = $dbname;

// Создаем соединение
$pdo = new PDO("mysql:host=$host;dbname=$db", $db, $pass);

// Получаем данные из запроса
$idusers = $_POST['idusers'];
$id = $_POST['id'];
$bd = $_POST['bd'];

// Проверяем наличие записи
$query = "SELECT * FROM likes WHERE idusers = ? AND id = ? AND bd = ?";
$stmt = $pdo->prepare($query);
$stmt->execute([$idusers, $id, $bd]);
$likeExists = $stmt->fetch();

if ($likeExists) {
// Если лайк есть, удаляем его
$query = "DELETE FROM likes WHERE idusers = ? AND id = ? AND bd = ?";
$stmt = $pdo->prepare($query);
$stmt->execute([$idusers, $id, $bd]);
echo "Like removed";
} else {
// Если лайка нет, добавляем его
$query = "INSERT INTO likes (idusers, id, bd) VALUES (?, ?, ?)";
$stmt = $pdo->prepare($query);
$stmt->execute([$idusers, $id, $bd]);
echo "Like added";
}
?>