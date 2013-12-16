#!/bin/bash

DOCKER_IMAGE=essa/mysql-repl

if [ $# -ne 1 ]; then
  echo "usage: start_slave.sh MASTER_HOST"
  exit 1
fi

rm data/mysql/init_slave.sh
cat > data/mysql/init_slave.sh <<SLAVE
#!/bin/bash
chown -R mysql:mysql /var/lib/mysql
mysqld_safe --server-id=2 --log-bin=mysql-bin --log-slave-updates=1 & 
pid=$!
sleep 5
echo "stop slave; change master to MASTER_HOST='${1}'; start slave" | mysql
wait $pid
SLAVE

chmod 755 data/mysql/init_slave.sh
docker run -d -p 3306:3306 -v `pwd`/data/mysql:/var/lib/mysql:rw $DOCKER_IMAGE /var/lib/mysql/init_slave.sh


