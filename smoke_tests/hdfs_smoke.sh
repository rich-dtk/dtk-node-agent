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






#!/usr/bin/env bash

#set -e

# execute health check script
# are all required services up and running
# if not break a script

export START_TIME=$(date +%s)


## Health script TBD

# BEGIN Utility functions
error_highlight()
{
	echo -e "\033[0;31m${1}\033[m"
}

# Shows highlighted info messages
warning_highlight(){
	echo -e "\033[1;33m${1}\033[m"
}

# Shows highlighted info messages
info_highlight(){
	echo -e "\033[0;32m${1}\033[m"
}

# Calculates the interval between two timestamps
calculate_time_internal(){
	let DURATION_SECONDS=$(($2 - $1))

	if [ ${DURATION_SECONDS} -ge 60 ] ; then
		let DURATION_MINUTES=$((DURATION_SECONDS/60))
		DURATION="$((DURATION_SECONDS-DURATION_MINUTES*60))s"
		if [ ${DURATION_MINUTES} -ge 60 ] ; then
			let DURATION_HOURS=$((DURATION_MINUTES/60))
			DURATION="${DURATION_HOURS}h $((DURATION_MINUTES-DURATION_HOURS*60))m ${DURATION}"
		else
			DURATION="${DURATION_MINUTES}m ${DURATION}"
		fi

	else
		DURATION="${DURATION_SECONDS}s"
	fi

	export CALCULATE_TIME_RESULT="${DURATION}"
}

# Calculates the time that passed between two timestamps and displays it to the user
calculate_time(){
	calculate_time_internal ${1} ${2}
	info_highlight "${3} executed in ${CALCULATE_TIME_RESULT}.\n"
}
# END Utility functions


#### SMOKE TESTS	
# Check filesystem health
hdfs fsck /  &> /dev/null
export t0_status=$?
if [[ "$t0_status" -ne "0" ]];
then
        echo ""
        error_highlight "[ERROR] HDFS check failed. INCONSISTENT STATE!!!"
else
        echo ""
        info_highlight "[INFO] HDFS is in CONSISTENT state"
fi

# Check if /tmp directory existing and writeable
hdfs dfs -test -d /tmp &> /dev/null
export t1_1_status=$?
hdfs dfs -mkdir /tmp/test &> /dev/null
export t1_2_status=$?
let t1_status=$(($t1_1_status + $t1_2_status))
if [ "$t1_status" -ne "0" ]

then
        warning_highlight "[WARNING] HDFS /tmp directory is not created properly."
else
        info_highlight "[INFO] HDFS /tmp directory setup properly."
fi

# check if user is created
export current_user=$(whoami)
hdfs dfs -test -d /user/${current_user} &> /dev/null
export t2_status=$?
if [ "$t2_status" -ne "0" ]
then
        warning_highlight "[WARNING] User ${current_user} is missing hdfs home directory"
else
        info_highlight "[INFO] User ${current_user} created properly"
fi

# Check if user is able to create directory under root / - negative test
hdfs dfs -mkdir /test
export t3_status=$?
if [ "$t3_status" -ne "0" ]
then
        info_highlight "[INFO] User ${current_user} does not have privileges to write to HDFS root directory"
else
        error_highlight "[ERROR] Security issue!!! User ${current_user} is able to write to HDFS root directory"
fi



## Overall smoke test results summary
let hadoop_status=${t0_status}+${t1_status}+${t2_status}+${t3_status}
echo ""
echo ""
        echo -e "+-----------------------------------------------------------------------------------------------+"
        echo -e "|                                                                                               |"
        echo -e "|                                    HADOOP SMOKE TEST STATUS                                    |"
if [[ "$hbase_status" -gt "10" ]];
then
        error_highlight "|[ERROR] HBase is not setup correctly.                                                         |"
        error_highlight "|[ERROR] Please check Your configuration and status of services                                |"
        echo -e "|                                                                                               |"
        echo -e "+-----------------------------------------------------------------------------------------------+"
else
		info_highlight "|[INFO] HBase smoke tests PASSED!                                                               |"
        echo -e "|                                                                                               |"
        echo -e "+-----------------------------------------------------------------------------------------------+"
fi

export END_TIME=$(date +%s)
echo " "
calculate_time "${START_TIME}" "${END_TIME}" "${0}"
