#!/usr/bin/env bash

set -e

# execute health check script
# are all required services up and running
# if not break a script

## Health script TBD

#check filesystem health
hdfs fsck /

#chek is root writable to all users - negative test
hdfs dfs -mkdir /test
[[ $? -ne "0" ]] && echo "[INFO] Passed!" && exit 0

#check if user is created
current_user=${whoami}
hdfs dfs -ls /user/${current_user}
[[ $? -ne "0" ]] && echo "[WARNING] User ${current_user} is not created properly" && exit 0




