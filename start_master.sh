#!/bin/bash
DOCKER_IMAGE=essa/mysql-repl

docker run -d -p 0.0.0.0:3306:3306 -v `pwd`/data/mysql:/var/lib/mysql:rw $DOCKER_IMAGE mysqld_safe --server-id=1 --log-bin=mysql-bin --log-slave-updates=1

