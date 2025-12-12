#!/bin/bash
set -e

echo "🚀 Starting MariaDB Wrapper..."

# 1. Starta i osäkert läge (bakgrunden) utan att försöka fånga PID
echo "🔓 Starting temporary server (skip-grant-tables)..."
/usr/sbin/mariadbd --datadir=/var/lib/mysql --bind-address=0.0.0.0 --skip-grant-tables &

# 2. Vänta på att den startar
echo "⏳ Waiting for server..."
sleep 10

# 3. Kör din SQL-fil
echo "📝 Running init_db.sql..."
mariadb -u root < /usr/local/bin/init_db.sql

# 4. Döda den tillfälliga servern med pkill (Säkrare metod)
echo "🛑 Stopping temporary server..."
pkill mariadbd

# Vänta tills processen verkligen är borta
echo "⏳ Waiting for shutdown..."
while pgrep mariadbd > /dev/null; do sleep 1; done

# 5. Starta på riktigt
echo "🔥 Starting MariaDB (Secure mode)..."
exec /usr/sbin/mariadbd --datadir=/var/lib/mysql --bind-address=0.0.0.0