#!/bin/bash

# modified from
# https://github.com/paulczar/docker-wordpress/blob/master/docker
#

DOCKER_IMAGE=essa/mysql-repl

echo 
echo "Create MySQL Tier"
echo "-----------------"
echo "* Create MySQL01"

if [ -d data/mysql ]; then
	echo "using existing DB"
else
	mkdir -p data/mysql
	cp ./initialize_db.sh data/mysql
	MYSQL01=$(docker run -d -v `pwd`/data/mysql:/var/lib/mysql:rw $DOCKER_IMAGE /var/lib/mysql/initialize_db.sh)
	docker wait $MYSQL01
	# docker logs $MYSQL01
fi
MYSQL01=$(docker run -d -v `pwd`/data/mysql:/var/lib/mysql:rw $DOCKER_IMAGE mysqld_safe --server-id=1 --log-bin=mysql-bin --log-slave-updates=1)
MYSQL01_IP=$(docker inspect $MYSQL01 | grep IPAd | awk -F'"' '{print $4}')

# echo $MYSQL01
# echo $MYSQL01_IP
# docker ps

echo "* Create MySQL02"

rm -rf replica
mkdir -p replica/data/mysql
cp Dockerfile *.sh *.cnf replica
cp ./initialize_db.sh replica/data/mysql

MYSQL02=$(docker run -d -v `pwd`/replica/data/mysql:/var/lib/mysql:rw $DOCKER_IMAGE /var/lib/mysql/initialize_db.sh)
docker wait $MYSQL02
docker logs $MYSQL02

MYSQL02=$(docker run -d -v `pwd`/replica/data/mysql:/var/lib/mysql:rw $DOCKER_IMAGE mysqld_safe --server-id=2 --log-bin=mysql-bin --log-slave-updates=1)
MYSQL02_IP=$(docker inspect $MYSQL02 | grep IPAd | awk -F'"' '{print $4}')

echo $MYSQL02
echo $MYSQL02_IP
docker ps

echo "* Sleep for two seconds for servers to come online..."
sleep 2

echo "* Creat replication user"

mysql -uroot -proot -h $MYSQL01_IP -AN -e 'GRANT REPLICATION SLAVE ON *.* TO "replication"@"%" IDENTIFIED BY "password";'
mysql -uroot -proot -h $MYSQL01_IP -AN -e 'flush privileges;'


echo "* Export Data from MySQL01 to MySQL02"

mysqldump -uroot -proot -h $MYSQL01_IP --single-transaction --all-databases \
        --flush-privileges | mysql -uroot -proot -h $MYSQL02_IP

echo "* Set MySQL01 as master on MySQL02"

MYSQL01_Position=$(mysql -uroot -proot -h $MYSQL01_IP -e "show master status \G" | grep Position | awk '{print $2}')
MYSQL01_File=$(mysql -uroot -proot -h $MYSQL01_IP -e "show master status \G"     | grep File     | awk '{print $2}')

mysql -uroot -proot -h $MYSQL02_IP -AN -e "CHANGE MASTER TO master_host='master', master_port=3306, \
        master_user='replication', master_password='password', master_log_file='$MYSQL01_File', \
        master_log_pos=$MYSQL01_Position;"

echo "* Start Slave"
mysql -uroot -proot -h $MYSQL02_IP -AN -e "start slave;"

echo "* Test replication"
mysql -uroot -proot -h $MYSQL01_IP -e "drop database if exists repltest; create database repltest;"
mysql -uroot -proot -h $MYSQL01_IP  repltest < repltest.sql

echo "* Sleep 2 seconds, then check that database 'repltest' exists on MySQL02"

sleep 2
mysql -uroot -proot -h $MYSQL02_IP -e "show databases; \G" | grep repltest
if mysql -uroot -proot -h $MYSQL02_IP -e "select title from test where id = 1234 ; " repltest  | grep 'If you see this message, replication is OK' ; then
	echo "* Everything is OK. Kill the containers"
	docker kill $MYSQL01
	docker kill $MYSQL02
else
	echo "can't find replicated data on MYSQL02"
	exit 1
fi





