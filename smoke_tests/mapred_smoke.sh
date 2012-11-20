#!/usr/bin/env bash

set -e
hadoop_home="/usr/lib/hadoop"
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
# Check if current user exist, if not create it

export current_user=$(whoami)
hdfs dfs -test -d /user/${current_user} &> /dev/null
export t1_status=$?
if [ "$t1_status" -ne "0" ]
then
        warning_highlight "[WARNING] User ${current_user} is missing hdfs home directory"
		info_highlight "[INFO] User's directory will be created"
		sudo -u hdfs hdfs dfs -mkdir /user/${current_user}
		sudo -u hdfs hdfs dfs -chown ${current_user}:${current_user} /user/${current_user}
		hdfs dfs -test -d /user/${current_user} &> /dev/null
		export t1_status=$?
		if [ "$t1_status" -ne "0" ]
			then 
				warning_highlight "[ERROR] User's ${current_user} hdfs home directory is not created"
				exit 1;
			else
				info_highlight "[INFO] User's directory created"
else
        info_highlight "[INFO] User ${current_user} created properly"
fi


[[ $? -ne "0" ]] && echo "Hadoop job failed." && exit 1


# Check if user is able to create directory under root / - negative test
hadoop jar ${hadoop_home}/hadoop-examples.jar pi 3 1
export t2_status=$?
if [ "$t2_status" -ne "0" ]
then
        error_highlight "[ERROR] User ${current_user} is not able to run MR job"
else
        info_highlight "[INFO] MR job started!"
fi



## Overall smoke test results summary
let hadoop_status=${t0_status}+${t1_status}
echo ""
echo ""
        echo -e "+-----------------------------------------------------------------------------------------------+"
        echo -e "|                                                                                               |"
        echo -e "|                                    MAPREDUCE SMOKE TEST STATUS                                    |"
if [[ "$hbase_status" -gt "10" ]];
then
        error_highlight "|[ERROR] MAPREDUCE is not setup correctly.                                                         |"
        error_highlight "|[ERROR] Please check Your configuration and status of services                                |"
        echo -e "|                                                                                               |"
        echo -e "+-----------------------------------------------------------------------------------------------+"
else
		info_highlight "|[INFO] MAPREDUCE smoke tests PASSED!                                                               |"
        echo -e "|                                                                                               |"
        echo -e "+-----------------------------------------------------------------------------------------------+"
fi

export END_TIME=$(date +%s)
echo " "
calculate_time "${START_TIME}" "${END_TIME}" "${0}"
