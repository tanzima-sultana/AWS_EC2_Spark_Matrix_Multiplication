#!/bin/bash
set -euo pipefail

# Load local config
if [ -f "config.env" ]; then
    # shellcheck disable=SC1091
    source config.env
else
    echo "ERROR: config.env not found!"
    echo "Please create one using:  cp config.env.template config.env"
    exit 1
fi  

# ----- Copy the project folder to master node
rsync -av \
  -e "ssh -i \"$KEY_PATH_LOCAL/$KEY\"" \
  --exclude='.git' \
  "$PROJECT_PATH_LOCAL/$SPARK_MATRIX_MUL_PROJECT" \
  "ubuntu@$MASTER_PUBLIC_IP:$PROJECT_PATH_CLOUD"

# ----- SSH to master node using public IP
ssh -i "$KEY_PATH_LOCAL/$KEY" "ubuntu@$MASTER_PUBLIC_IP"
