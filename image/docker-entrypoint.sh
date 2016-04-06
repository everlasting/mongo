#!/bin/bash

NUM_NODES=3

numa='numactl --interleave=all'
if  ! $numa true &> /dev/null ; then
	numa=''
fi

if [[ "$(id -u)" = '0' ]]; then
	chown -R mongodb /data/db
	sudo='gosu mongodb'
fi

function launchRepliSet() {
	if [[ -n "${RepliSetName}" ]]; then
		echo "${sudo} ${numa} mongod --shardsvr --replSet ${RepliSetName}"
		exec ${sudo} ${numa} mongod --shardsvr --replSet ${RepliSetName} --port 27017
	else
		echo "you must set replication set name!"
		exit 1
	fi
}
	
function launchConfigSvr() {
	echo "${sudo} ${numa} mongod --configsvr --port 20000"
	exec ${sudo} ${numa} mongod --configsvr --port 20000
}
	
function launchMongos() {
	echo "rs1 = ${RS1_SERVICE_HOST}"
	echo "rs2 = ${RS2_SERVICE_HOST}"
	echo "rs3 = ${RS3_SERVICE_HOST}"
	echo "config1 = ${CONFIGSVR1_SERVICE_HOST}"
	echo "config2 = ${CONFIGSVR2_SERVICE_HOST}"
	echo "config3 = ${CONFIGSVR3_SERVICE_HOST}"
	echo "mongos1 = ${MONGOS1_SERVICE_HOST}"
	echo "mongos2 = ${MONGOS2_SERVICE_HOST}"
	echo "mongos3 = ${MONGOS3_SERVICE_HOST}"
	echo "rs0 = ${RepliSetName}"

	InitNodes=$(echo "rs.status()" | mongo ${RS1_SERVICE_HOST}:27017 --shell 2> /dev/null | grep '_id' | wc -l)
	
	if [[ -z "${RepliSetName}" ]]; then
		echo "you must set replication set name!"
		exit 1
	fi
	
	if [[ "$InitNodes" -eq 0 ]];then          #first mongos launch will set replication set
 		for NUM in `seq 1 $NUM_NODES`; do
			RS_SERVICE_HOST="RS${NUM}_SERVICE_HOST"
			
			echo "RS_SERVICE_HOST = $RS_SERVICE_HOST"
			echo "rs.initiate({ _id: \""${RepliSetName}"\", members: [ {_id: 0, host: \""$RS1_SERVICE_HOST:27017"\"},{_id: 1, host: \""$RS2_SERVICE_HOST:27017"\"},{_id: 2, host: \""$RS3_SERVICE_HOST:27017"\"}]})" | mongo ${!RS_SERVICE_HOST}:27017 --shell
			echo "rs.initiate({ _id: \""${RepliSetName}"\", members: [ {_id: 0, host: \""$RS1_SERVICE_HOST:27017"\"},{_id: 1, host: \""$RS2_SERVICE_HOST:27017"\"},{_id: 2, host: \""$RS3_SERVICE_HOST:27017"\"}]})"
			InitNodes=$(echo "rs.status()" | mongo ${!RS_SERVICE_HOST}:27017 --shell 2> /dev/null | grep '_id' | wc -l)
			
			echo "InitNodes = $InitNodes"
			if [[ "$InitNodes" -ge "$NUM_NODES" ]];then	
				break
			fi
		done
	fi
	
	for NUM in `seq 1 $NUM_NODES`; do   #second mongos launch will  add sharding
		MONGOS_SERVICE_HOST="MONGOS${NUM}_SERVICE_HOST"
		if [[ -n "${!MONGOS_SERVICE_HOST}" ]];then
			echo "MONGOS_SERVICE_HOST = ${!MONGOS_SERVICE_HOST}"
			failedConn=$(mongo ${!MONGOS_SERVICE_HOST}:30000 | grep -E "[F|f]ailed|error")
			echo "failedconn => $failedConn"
			if [[ -z "$failedConn" ]];then
				sharded=$(echo "db.printShardingStatus()" | mongo ${!MONGOS_SERVICE_HOST}:30000 --shell 2> /dev/null | grep "${RepliSetName}")
				echo "sharded => $sharded"
				if [[ -z "$sharded" ]];then
					mongo ${!MONGOS_SERVICE_HOST}:30000 --eval "db=db.getSiblingDB(\"admin\"); db.runCommand({addshard:\""${RepliSetName}"/$RS1_SERVICE_HOST:27017,$RS2_SERVICE_HOST:27017,$RS3_SERVICE_HOST:27017\"})"
					sharded=$(echo "db.printShardingStatus()" | mongo ${!MONGOS_SERVICE_HOST}:30000 --shell 2> /dev/null | grep "${RepliSetName}")
					if [[ -n "$sharded" ]];then
						break
					else
						echo "can not add sharding!"
						exit 1
					fi
				fi
			fi
		fi
		
	done	
	
	echo "mongos --configdb $CONFIGSVR1_SERVICE_HOST:20000,$CONFIGSVR2_SERVICE_HOST:20000,$CONFIGSVR3_SERVICE_HOST:20000 --port 30000 --chunkSize 256"	 
	exec ${sudo} mongos --configdb $CONFIGSVR1_SERVICE_HOST:20000,$CONFIGSVR2_SERVICE_HOST:20000,$CONFIGSVR3_SERVICE_HOST:20000 --port 30000 --chunkSize 256   #first mongos launch
}	
	
if [[ "${REPLISET}" == "true" ]]; then
	launchRepliSet
	exit 0
fi

if [[ "${CONFIGSVR}" == "true" ]]; then
	launchConfigSvr
	exit 0
fi

if [[ "${MONGOS}" == "true" ]]; then
	launchMongos
	exit 0
fi

exec ${sudo} ${numa} mongod
