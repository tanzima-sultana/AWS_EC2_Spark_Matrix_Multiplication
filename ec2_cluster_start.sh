#!/bin/bash

# Master and Worker are Private IPs
MASTER_IP=<master_private_ip>

WORKER_1=<worker1_private_ip>
WORKER_2=<worker2_private_ip>

# Start Spark master on the master node's private IP
$SPARK_HOME/sbin/start-master.sh

# SSH into Worker 1 and start the worker using the master's private IP
ssh -i /home/ubuntu/<public_key> -v ubuntu@$WORKER_1 "$SPARK_HOME/sbin/start-worker.sh spark://$MASTER_IP:7077"

# SSH into Worker 2 and start the worker using the master's private IP
ssh -i /home/ubuntu/<public_key> -v ubuntu@$WORKER_2 "$SPARK_HOME/sbin/start-worker.sh spark://$MASTER_IP:7077"


