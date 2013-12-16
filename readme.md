
A sample scripts to run a mysql server with replication.

Inspired from https://github.com/paulczar/docker-wordpress.

# preparation

1. get two hosts running
2. install docker and mysql-client to both hosts
3. open ssh port from master to slave
4. open mysql port (3306) from slave to master

# usage

at the master

    $ git clone https://github.com/essa/docker-mysql-repl.git
    $ cd docker-mysql-repl
    $ sudo docker build -t essa/mysql-repl .
    $ sudo ./create_repl.sh
    $ ./copy_replica.sh SLAVE_HOST
    $ sudo ./start_master.sh 
    $ mysql -uroot -proot -h 127.0.0.1 -AN  repltest

at the slave

    $ cd replica
    $ sudo docker build -t essa/mysql-repl .
    $ sudo ./start_slave.sh MASTER_HOST
    $ mysql -uroot -proot -h 127.0.0.1 -AN repltest

at the master

    mysql> insert into test values(2345, 'You will see this message in the slave');

at the slave

    mysql> select * from test;
    +------+--------------------------------------------+
    | 1234 | If you see this message, replication is OK |
    | 2345 |     You will see this message in the slave |
    +------+--------------------------------------------+

