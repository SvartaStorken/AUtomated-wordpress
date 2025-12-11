#!/bin/bash
set -e

# Sökvägar
# I UBI 9/10 med MariaDB standard-paket ligger datan här
DB_DATA_DIR="/var/lib/mysql"
SOCKET_DIR="/var/run/mariadb"

# 1. SIGNALHANTERING
# Om OpenShift säger "Stopp!", stäng ner snyggt.
trap "echo 'Stopping MariaDB...'; mysqladmin shutdown; exit 0" SIGTERM SIGINT

# Se till att socket-katalogen finns och har rättigheter
if [ ! -d "$SOCKET_DIR" ]; then
    mkdir -p "$SOCKET_DIR"
    # Använder din fix-permissions logik här för säkerhets skull
    chgrp 0 "$SOCKET_DIR"
    chmod g+rwX "$SOCKET_DIR"
fi

# 2. INITIERING
# Vi kollar om mappen 'mysql' (systemtabellerna) finns. Om inte, är det tomt.
if [ ! -d "$DB_DATA_DIR/mysql" ]; then
    echo "Initializing database data..."
    
    # Motsvarigheten till Postgres 'initdb'
    # --rpm: Säger åt den att inte bråka om konfigurationsfiler
    mariadb-install-db --user=mysql --datadir="$DB_DATA_DIR" --rpm > /dev/null

    # 3. SKAPA ANVÄNDARE OCH DATABAS (Temp-start)
    echo "Starting temporary server to create users..."
    
    # Starta servern i bakgrunden (&) utan nätverk
    mariadbd --datadir="$DB_DATA_DIR" --socket="$SOCKET_DIR/mysql.sock" --skip-networking &
    PID=$!

    # Vänta tills servern svarar (pinga den)
    echo "Waiting for temp server..."
    for i in {30..0}; do
        if mysqladmin ping --socket="$SOCKET_DIR/mysql.sock" --silent; then
            break
        fi
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo >&2 "MariaDB start failed."
        exit 1
    fi

    echo "Creating user ${MARIADB_USER} and database ${MARIADB_DATABASE}..."
    
    # Kör SQL-kommandon för att skapa användaren
    mariadb --socket="$SOCKET_DIR/mysql.sock" <<-EOSQL
        -- Skapa databasen
        CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
        
        -- Skapa användaren (tillåt från alla hostar '%')
        CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
        
        -- Ge rättigheter
        GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
        
        -- Spara och rensa
        FLUSH PRIVILEGES;
EOSQL

    echo "Stopping temporary server..."
    mysqladmin shutdown --socket="$SOCKET_DIR/mysql.sock"
    wait $PID
    echo "Initialization complete."
fi

# 4. START (Skarpt läge)
echo "Starting MariaDB..."
# exec gör att MariaDB tar över processen (viktigt för loggar och signaler)
exec mariadbd --datadir="$DB_DATA_DIR" --user=mysql --bind-address=0.0.0.0
