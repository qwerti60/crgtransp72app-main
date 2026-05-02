<?// Include the database configuration file
include 'databd.php';

// Create a new MySQLi connection
$conn = new mysqli($host, $username, $password, $dbname);

// Check for connection errors
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
// Set the charset to UTF-8
$conn->set_charset("utf8");

// Retrieve the POST data
$rollNum = $_POST['rollNum'];
$statNum = $_POST['statNum'];
$firstName = $_POST['firstName'];
$middleName = $_POST['middleName'];
$lastName = $_POST['lastName'];
$city = $_POST['city'];
$phone = $_POST['phone'];
$email = $_POST['email'];
$password = $_POST['password'];
$namefirm = $_POST['namefirm'];
$innStr = $_POST['innStr'];
$ogrnStr = $_POST['ogrnStr'];
$kppStr = $_POST['kppStr'];
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);
// Prepare the SQL statement with positional placeholders
$sql = "INSERT INTO users (rollNum, statNum, firstName, middleName, lastName, city, phone, email, password, namefirm, innStr, ogrnStr, kppStr)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);

// Check if the statement was prepared successfully
if ($stmt) {
    // Bind the parameters to the statement
    $stmt->bind_param("issssssssssss", $rollNum, $statNum, $firstName, $middleName, $lastName, $city, $phone, $email, $hashedPassword, $namefirm, $innStr, $ogrnStr, $kppStr);

    // Execute the statement
    if ($stmt->execute()) {
        echo json_encode(array('status' => 'success'));
    } else {
        echo json_encode(array('status' => 'error', 'message' => $stmt->error));
    }

    // Close the statement
    $stmt->close();
} else {
    // Output any errors that occurred during the preparation of the statement
    echo json_encode(array('status' => 'error', 'message' => $conn->error));
}

// Close the connection
$conn->close();
?>
