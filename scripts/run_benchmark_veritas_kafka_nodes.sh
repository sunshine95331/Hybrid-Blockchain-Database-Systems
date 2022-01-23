#!/bin/bash

. ./env.sh

set -x

TSTAMP=`date +%F-%H-%M-%S`
LOGS="logs-nodes-veritas-kafka-$TSTAMP"
mkdir $LOGS

DRIVERS=$DEFAULT_DRIVERS_VERITAS_KAFKA
THREADS=$DEFAULT_THREADS_VERITAS_KAFKA
WORKLOAD_FILE="$DEFAULT_WORKLOAD_PATH/$DEFAULT_WORKLOAD".dat
WORKLOAD_RUN_FILE="$DEFAULT_WORKLOAD_PATH/run_$DEFAULT_WORKLOAD".dat

for N in $NODES; do
    ./restart_cluster_veritas.sh $(($N+1))
    ./start_veritas_kafka.sh $(($N+1))

    # Generate server addresses. Veritas port is 1990
    ADDRS="$IPPREFIX.2:1990"
    for IDX in `seq 3 $(($N+1))`; do
        ADDRS="$ADDRS,$IPPREFIX.$IDX:1990"
    done
        
    ../bin/veritas-kafka-bench --load-path=$WORKLOAD_FILE --run-path=$WORKLOAD_RUN_FILE --ndrivers=$DRIVERS --nthreads=$THREADS --veritas-addrs=$ADDRS --tso-addr=:7070 2>&1 | tee $LOGS/veritas-nodes-$N.txt

    sleep 10
    SLOGS=$LOGS/veritas-nodes-$N-logs
    mkdir -p $SLOGS
    for I in `seq 2 $(($N+1))`; do
        IDX=$(($I-1))
        scp -o StrictHostKeyChecking=no root@1$IPPREFIX.$I:/veritas-$IDX.log $SLOGS/
    done
    KAFKA_HOST="$IPPREFIX.$(($N+2))"
    scp -o StrictHostKeyChecking=no root@$KAFKA_HOST:/kafka_2.12-2.7.0/zookeeper.log $SLOGS/
    scp -o StrictHostKeyChecking=no root@$KAFKA_HOST:/kafka_2.12-2.7.0/kafka.log $SLOGS/
    ssh -o StrictHostKeyChecking=no root@$KAFKA_HOST "cd /kafka_2.12-2.7.0 && ./bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list" | tee -a $SLOGS/kafka-counters.log
    for I in `seq 1 $N`; do
	    ssh -o StrictHostKeyChecking=no root@$KAFKA_HOST "cd /kafka_2.12-2.7.0 && ./bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group $I" | tee -a $SLOGS/kafka-counters.log
    done
done
sudo ./unset_ovs_veritas.sh
./kill_containers_veritas.sh
