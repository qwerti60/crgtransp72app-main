<?
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

$host = 'localhost';
$db = 'u2395188_apps';
$user = 'u2395188_apps72';
$pass = 'kR3iV2aA6gjU8nC9';
$dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";

try {
$pdo = new PDO($dsn, $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
die(json_encode(["error" => "Connection failed: " . $e->getMessage()]));
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['username'])) {
echo json_encode(["error" => "Username is required"]);
exit();
}

$username = $data['username'];
$stmt = $pdo->prepare("SELECT * FROM users1 WHERE username = ?");
$stmt->execute([$username]);

if ($stmt->rowCount() > 0) {
echo json_encode(["exists" => true]);
} else {
echo json_encode(["exists" => false]);
}
} else {
echo json_encode(["error" => "Invalid request method"]);
}
?>
