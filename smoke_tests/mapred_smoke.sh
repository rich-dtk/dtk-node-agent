#!/usr/bin/env bash
#set -e

# execute health check script
# are all required services up and running
# if not break a script

hadoop_home="/usr/lib/hadoop"

sudo -u hdfs hadoop fs -chmod 777 /user

hadoop jar ${hadoop_home}/hadoop-examples.jar pi 3 1
[[ $? -ne "0" ]] && echo "Hadoop job failed." && exit 1

# check if user is created
current_user=${whoami}
hdfs dfs -ls /user/${current_user}
[[ $? -ne "0" ]] && echo "[WARNING] User ${current_user} is not created properly" && exit 0

# Check if /tmp directory exists
hdfs dfs -test -d /mladen
[[ $? -ne "0" ]] && echo "[WARNING]Directory does not exist." && exit 1
# 