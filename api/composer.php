<?
require_once '/var/www/u2395188/data/vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

$key = "example_key";
$token = array(
    "iss" => "http://example.org",
    "aud" => "http://example.com",
    "iat" => 1356999524,
    "nbf" => 1357000000
);

$jwt = JWT::encode($token, $key, 'HS256');
echo $jwt;

// Декодирование
$decoded = JWT::decode($jwt, new Key($key, 'HS256'));
print_r($decoded);
?>