#!/bin/bash

if [ $# -ne 1 ]; then
  echo "usage: copy_replica.sh SLAVE_HOST"
  exit 1
fi

sudo tar zcvf - replica | ssh $1 tar zxvf -


