#!/bin/bash

BWS="NoLimit 10000 1000 100"
RTTS="5ms 10ms 20ms 30ms 40ms 50ms 60ms"

TSTAMP=`date +%F-%H-%M-%S`
LOGS="logs-networking-veritas-tendermint-$TSTAMP"
mkdir $LOGS

THREADS=32
ADDRS="http://192.168.20.2:26656,http://192.168.20.3:26656,http://192.168.20.4:26656,http://192.168.20.5:26656"

set -x

for BW in $BWS; do    
    for RTT in $RTTS; do
	    LOGSD="$LOGS/logs-$BW-$RTT"
	    mkdir $LOGSD
        ./restart_cluster_veritas.sh
        if [[ "$BW" != "NoLimit" ]]; then
            sudo ./set_ovs_bs_limit.sh $BW 1
        fi
	    ./set_tc.sh $RTT
	    sleep 3
        ./start_veritas_tendermint.sh
	    ./run_iperf_ping.sh 2>&1 | tee $LOGSD/net.txt
	    sleep 3
        ../bin/veritas-tendermint-bench --load-path=temp/ycsb_data/workloada.dat --run-path=temp/ycsb_data/run_workloada.dat --nthreads=$THREADS --urls=$ADDRS 2>&1 | tee $LOGS/veritas-$BW-$RTT.txt
    done
done