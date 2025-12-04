#!/bin/bash
set -euo pipefail

# Load local config
if [ -f "config.env" ]; then
    source config.env
else
    echo "ERROR: config.env not found!"
    echo "Please create one using:  cp config.env.template config.env"
    exit 1
fi     


# ----- Stop worker
ssh -i "$KEY_PATH_CLOUD/$KEY" ubuntu@"$WORKER_1_PRIVATE_IP" "$SPARK_HOME/sbin/stop-worker.sh spark://$MASTER_PRIVATE_IP:7077"
ssh -i "$KEY_PATH_CLOUD/$KEY" ubuntu@"$WORKER_2_PRIVATE_IP" "$SPARK_HOME/sbin/stop-worker.sh spark://$MASTER_PRIVATE_IP:7077"


# ----- Stop Master 
$SPARK_HOME/sbin/stop-master.sh



