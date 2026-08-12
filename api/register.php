<?php
require __DIR__ . '/load_databd.php';
$servername = $host;

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
die("Connection failed: " . $conn->connect_error);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
$username = $_POST['username'];
$email = $_POST['email'];
$password = password_hash($_POST['password'], PASSWORD_DEFAULT);


if ($username && $email && $password) {
$stmt = $conn->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $username, $email, $password);

if ($stmt->execute()) {
echo json_encode(["status" => "success"]);
} else {
echo json_encode(["status" => "error", "message" => "User registration failed"]);
}
$stmt->close();
}

$conn->close();
} else {
echo "Invalid request method";
}
?>