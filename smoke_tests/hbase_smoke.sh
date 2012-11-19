
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
hbase hbck  &> /dev/null
export t0_status=$?
if [[ "$t0_status" -ne "0" ]];
then
        echo ""
        error_highlight "[ERROR] HBase check failed. INCONSISTENT STATE!!!"
else
        echo ""
        info_highlight "[INFO] HBase is in CONSISTENT state"
fi

#check if user is created
export current_user=$(whoami)
hdfs dfs -test -d /user/${current_user} &> /dev/null
export t1_status=$?
if [ "$t1_status" -ne "0" ]
then
        warning_highlight "[WARNING] User ${current_user} is missing hdfs home directory"
else
        info_highlight "[INFO] User ${current_user} created properly"
fi

# Check if user is able to create table
# TO DO: Add grep of output to be able to get results of this command
export log_file=create_table.log.$(date +"%s")
export table_name=SMOKETEST_$(date +"%s")

hbase shell <<EOL &> ${log_file}
create '${table_name}', {NAME => 'COLUMN_FAMILY', VERSIONS => 5};
quit
EOL

## Check if table is successfully created
export is_passed=$(cat $log_file | egrep -i '(Table already exists|ERROR:|NoServerForRegionException|RegionOfflineException|RetriesExhaustedException|ScannerTimeoutException)')

if [ "$is_passed" != "" ]
then
        export t2_status=10
        error_highlight "[ERROR] Table creation failed, reason: $is_passed"
else
        info_highlight "[INFO] Table ${table_name} created successfully"
        export t2_status=0
fi

## for demo purpose...will be removed
sleep 15

### SMOKE TEST Cleanup
info_highlight "[INFO] Smoke test data cleanup..." >> ${log_file}
hbase shell <<EOL &> /dev/null >> ${log_file}
disable '${table_name}';
drop '${table_name}';
quit
EOL


## Overall smoke test results summary
let hbase_status=${t0_status}+${t1_status}+${t2_status}
echo ""
echo ""
        echo -e "+-----------------------------------------------------------------------------------------------+"
        echo -e "|                                                                                               |"
        echo -e "|                                    HBASE SMOKE TEST STATUS                                    |"
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