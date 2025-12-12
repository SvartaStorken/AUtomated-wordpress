FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS wordpress_db;

CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY 'hemligt';
CREATE USER IF NOT EXISTS 'wordpress'@'localhost' IDENTIFIED BY 'hemligt';

GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'%';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'localhost';

ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('hemligt');
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

FLUSH PRIVILEGES;