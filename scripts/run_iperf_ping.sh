#!/bin/bash

. ./env.sh

HOST1="$IPPREFIX.2"
HOST2="$IPPREFIX.3"

ssh -o StrictHostKeyChecking=no root@$HOST1 "killall -9 iperf"
sleep 1
ssh -o StrictHostKeyChecking=no root@$HOST1 "iperf -s" &
sleep 3
ssh -o StrictHostKeyChecking=no root@$HOST2 "iperf -c $HOST1"
sleep 3
ssh -o StrictHostKeyChecking=no root@$HOST2 "ping -c 10 $HOST1"
ssh -o StrictHostKeyChecking=no root@$HOST1 "killall -9 iperf"
