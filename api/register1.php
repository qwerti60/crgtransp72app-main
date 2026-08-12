<?
// Include the database configuration file
require __DIR__ . '/load_databd.php';

// Create a new MySQLi connection
$conn = new mysqli($host, $username, $password, $dbname);

// Check for connection errors
if ($conn->connect_error) {
die(json_encode(array('status' => 'error', 'message' => 'Connection failed: ' . $conn->connect_error)));
}
// Set the connection to use UTF-8 encoding
$conn->set_charset("utf8");

// Get the JSON data from the request
$data = json_decode(file_get_contents('php://input'), true);

// Check if the required parameters are present
if (!isset($data['rollNum'], $data['statNum'], $data['firstName'], $data['lastName'], $data['middleName'], $data['city'], $data['phone'], $data['email'], $data['password'], $data['namefirm'], $data['innStr'], $data['ogrnStr'], $data['kppStr'], $data['vidt'], $data['marka'], $data['godv'], $data['maxgruz'], $data['dkuzov'], $data['shkuzov'], $data['vidk'], $data['cenahaurs'], $data['cenasmena'], $data['cenakm'])) {
echo json_encode(array('status' => 'error', 'message' => 'Missing parameters'));
exit();
}

// Prepare an SQL statement to insert the data into the database
$stmt = $conn->prepare("INSERT INTO users (rollNum, statNum, firstName, lastName, middleName, city, phone, email, password, namefirm, innStr, ogrnStr, kppStr, vidt, marka, godv, maxgruz, dkuzov, shkuzov, vidk, cenahaurs, cenasmena, cenakm, flag) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)");

if ($stmt === false) {
echo json_encode(array('status' => 'error', 'message' => 'Database error: ' . $conn->error));
exit();
}
if(isset($data['password'])) {
    $hashed_password = password_hash($data['password'], PASSWORD_DEFAULT);
} else {
    echo json_encode(array('status' => 'error', 'message' => 'Password is required'));
    exit();
}
// Bind the parameters to the SQL statement
$stmt->bind_param(
"iisssssssssssssisiisddd",
$data['rollNum'],
$data['statNum'],
$data['firstName'],
$data['lastName'],
$data['middleName'],
$data['city'],
$data['phone'],
$data['email'],
$hashed_password,
$data['namefirm'],
$data['innStr'],
$data['ogrnStr'],
$data['kppStr'],
$data['vidt'],
$data['marka'],
$data['godv'],
$data['maxgruz'],
$data['dkuzov'],
$data['shkuzov'],
$data['vidk'],
$data['cenahaurs'],
$data['cenasmena'],
$data['cenakm']
);

if ($stmt->execute()) {
echo json_encode(array('status' => 'success', 'message' => 'Registration successful'));
} else {
echo json_encode(array('status' => 'error', 'message' => 'Error: ' . $stmt->error));
}

$stmt->close();
$conn->close();
?>