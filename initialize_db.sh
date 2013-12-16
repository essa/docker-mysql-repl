#!/bin/bash

chown mysql.mysql /var/run/mysqld/
mysql_install_db
/usr/bin/mysqld_safe &
sleep 5
echo "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

