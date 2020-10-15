#! /bin/sh
#
# entrypoint.sh

set -e

[ -d /var/lib/mysql ] || mkdir -p /var/lib/mysql
[ -d /run/mysqld ] || mkdir -p /run/mysqld

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /run/mysqld

# Set environments
[ -d /var/lib/mysql/mysql ] || {
	echo "Creating initial database"

	mysql_install_db --user=mysql --ldata=/var/lib/mysql > /dev/null

	[ -z "$MYSQL_ROOT_PASSWORD" ] && {
		MYSQL_ROOT_PASSWORD=`pwgen 16 1`
		echo "root Password: $MYSQL_ROOT_PASSWORD"
	}

	MYSQL_DATABASE=${MYSQL_DATABASE:-""}
	MYSQL_USER=${MYSQL_USER:-""}
	MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}
	MYSQL_CHARSET=${MYSQL_CHARSET:-"utf8"}
	MYSQL_COLLATION=${MYSQL_COLLATION:-"utf8_general_ci"}

	tfile=`mktemp`
	[ -f "$tfile" ] || return 1

	cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES ;
GRANT ALL ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;
DROP DATABASE IF EXISTS test ;
FLUSH PRIVILEGES ;
EOF

	[ -z "$MYSQL_DATABASE" ] || {
		echo "Creating database: $MYSQL_DATABASE"
		echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET $MYSQL_CHARSET COLLATE $MYSQL_COLLATION;" >> $tfile
	}
	
	[ -z "$MYSQL_USER" ] || {
		echo "Creating user: $MYSQL_USER:$MYSQL_PASSWORD"
		echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
	}
	
	/usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < $tfile
	rm -f $tfile
	
}

# execute any pre-init scripts and inject sql
for f in /scripts/entrypoint.d/*; do
	case "$f" in
		*.sh) [ -e "$f" ] && "$f" ;;
		*.sql) echo "$0: injecting $f"; /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < "$f" ;;
		*.sql.gz) echo "$0: injecting $f"; gunzip -c "$f" | /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < "$f" ;;
	esac
done

exec "$@"
