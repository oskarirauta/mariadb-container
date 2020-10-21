FROM alpine:latest

ENV \
       MYSQL_ROOT_PASSWORD="" \
       MYSQL_DATABASE="" \
       MYSQL_USER="" \
       MYSQL_PASSWORD="" \
       MYSQL_CHARSET="utf8" \
       MYSQL_COLLATION="utf8_general_ci"

RUN \
        apk --no-cache update && \
        apk --no-cache upgrade && \
        apk --no-cache --update add mariadb mariadb-client mariadb-server-utils pwgen sudo busybox-suid
        
RUN \
        mkdir -p /scripts /scripts/entrypoint.d /run/mysqld /var/lib/mysql && \
        chown -R mysql:mysql /run/mysqld && \
        chown -R mysql:mysql /var/lib/mysql

RUN     rm -f /var/cache/apk/*

ADD entrypoint.sh /scripts/entrypoint.sh

EXPOSE 3306

VOLUME ["/var/lib/mysql"]
VOLUME ["/run/mysqld"]
VOLUME ["/scripts/entrypoint.d"]

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/usr/bin/mysqld", "--user=mysql", "--console", "--skip-name-resolve", "--skip-networking=0"]
