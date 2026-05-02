<?php
// db.php содержит подключение к базе данных MySQL
$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db = "u2395188_apps";
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
     $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
     throw new \PDOException($e->getMessage(), (int)$e->getCode());
}

$sql = "SELECT fotouser FROM users WHERE email='aaa@aaa.ru' LIMIT 1";
$stmt = $pdo->query($sql);

if ($row = $stmt->fetch())
{
    // Предполагая, что изображение хранится в формате BLOB
    $imageData = $row['fotouser'];
    // вывод изображения
    // Для base64
    // echo base64_encode($imageData);
    // Напрямую как изображение
    header('Content-Type: image/jpeg');
    echo $imageData;
} else {
    echo "Изображение не найдено!";
}
?>