<?php
// Устанавливаем заголовок Content-Type для ответа
header('Content-Type: application/json');

require __DIR__ . '/load_databd.php';


// Создаем подключение к базе данных
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем соединение
if ($conn->connect_error) {
die("Connection failed: " . $conn->connect_error);
}

// Запрос к базе данных
$sql = "SELECT city, marka, godv, maxgruz, dkuzov, shkuzov, vidk, cenahaurs, cenasmena, cenakm,
TO_BASE64(img1) AS img1, TO_BASE64(img2) AS img2, TO_BASE64(img3) AS img3, TO_BASE64(img4) AS img4, flag
FROM add_ob_gp";
$result = $conn->query($sql);

$rows = array();
if ($result->num_rows > 0) {
// Вывод всех строк
while($row = $result->fetch_assoc()) {
$rows[] = $row;
}
} else {
echo json_encode(["error" => "No results found"]);
exit;
}

// Закрываем соединение
$conn->close();

// Возвращаем результат в формате JSON
echo json_encode($rows);
?>