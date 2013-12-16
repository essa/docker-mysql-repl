
FROM ubuntu:12.04
MAINTAINER Taku Nakajima "takunakajima@gmail.com"

RUN apt-get update
RUN apt-get -y install mysql-server

ADD mysql-listen.cnf /etc/mysql/conf.d/mysql-listen.cnf

# Start mysql server
CMD ["/usr/bin/mysqld_safe"]

