<?php
require __DIR__ . '/load_databd.php';
$servername = $host;

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
die("Connection failed: " . $conn->connect_error);
}

$data = json_decode(file_get_contents("php://input"));

if (isset($data->username) && isset($data->email) && isset($data->password)) {
$username = $data->username;
$email = $data->email;
$password = password_hash($data->password, PASSWORD_DEFAULT);

$sql = "INSERT INTO users (username, email, password) VALUES ('$username', '$email', '$password')";

if ($conn->query($sql) === TRUE) {
echo json_encode(array("message" => "User registered successfully"));
} else {
echo json_encode(array("message" => "Error: " . $sql . "
" . $conn->error));
}
} else {
echo json_encode(array("message" => "Invalid input"));
}

$conn->close();
?>