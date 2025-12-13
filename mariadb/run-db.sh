mariadb/run-db.sh
#!/bin/bash
set -e

# Sätt defaults
DB_NAME=${MARIADB_DATABASE:-wordpress_db}
DB_USER=${MARIADB_USER:-wordpress}
DB_PASS=${MARIADB_PASSWORD:-hemligt}

echo "🚀 Starting MariaDB Wrapper..."

# --- NY FIX: Initiera databasen om disken är tom ---
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "✨ Volume is empty! Initializing new database..."
    mariadb-install-db --datadir=/var/lib/mysql --auth-root-authentication-method=normal
    echo "✅ Database initialized."
else
    echo "📂 Database files found. Skipping initialization."
fi
# ---------------------------------------------------

echo "👤 User: $DB_USER"
echo "🗄️  DB:   $DB_NAME"

# 1. Starta i osäkert läge
echo "🔓 Starting temporary server..."
/usr/sbin/mariadbd --datadir=/var/lib/mysql --bind-address=0.0.0.0 --skip-grant-tables &

# 2. Vänta
echo "⏳ Waiting for server..."
sleep 10

# 3. Kör SQL
echo "📝 Configuring Database..."
mariadb -u root <<-EOSQL
    FLUSH PRIVILEGES;
    CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
    CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
    GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
    GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
    ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_PASS');
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOSQL

# 4. Starta om
echo "🛑 Stopping temporary server..."
pkill mariadbd
echo "⏳ Waiting for shutdown..."
while pgrep mariadbd > /dev/null; do sleep 1; done

echo "🔥 Starting MariaDB (Secure mode)..."
exec /usr/sbin/mariadbd --datadir=/var/lib/mysql --bind-address=0.0.0.0