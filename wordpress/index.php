<?php
echo "<h1>🚀 Hello from Red Hat PHP 8.3 Image!</h1>";
echo "<p>Running on UBI 10.</p>";

$servername = "mariadb";
$username = getenv('DB_USER');
$password = getenv('DB_PASSWORD');
$dbname = getenv('DB_NAME'); // Bra att ha med

// Skapa anslutning
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
  die("<p style='color:red'>Connection failed: " . $conn->connect_error . "</p>");
}
echo "<p style='color:green'>Database connection successful! Connected to: <b>$dbname</b> 🎉</p>";

// Visa PHP info för att se versionen (valfritt)
// phpinfo();
?>
