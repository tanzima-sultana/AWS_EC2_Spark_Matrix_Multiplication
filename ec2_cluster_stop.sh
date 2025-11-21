#!/bin/bash

# Master and Worker are Private IPs
MASTER_IP=<master_private_ip>

WORKER_1=<worker1_private_ip>
WORKER_2=<worker2_private_ip>


# SSH into Worker 1 and stop the worker using the master's private IP
ssh -i /home/ubuntu/<public_key> -v ubuntu@$WORKER_1 "$SPARK_HOME/sbin/stop-worker.sh spark://$MASTER_IP:7077"

# SSH into Worker 2 and stop the worker using the master's private IP
ssh -i /home/ubuntu/<public_key> -v ubuntu@$WORKER_2 "$SPARK_HOME/sbin/stop-worker.sh spark://$MASTER_IP:7077"

# Last, stop master
$SPARK_HOME/sbin/stop-master.sh

