#!/bin/bash

### ==== CONFIG ==== ###
MIN_FREE_GB=1       # Require at least 1 GB free
PYTHON_PATH="/home/ubuntu/pyspark-env/bin/python"

# Use Spark standalone cluster master (private IP of master)
MASTER="spark://172.31.11.194:7077"

PACKAGES="org.apache.spark:spark-hadoop-cloud_2.13:4.0.1"

# You can tune these based on how many workers you have
# For now, assume 1 worker with 8 vCPUs
EXECUTOR_CORES=6
EXECUTOR_MEMORY="10G"
DRIVER_MEMORY="8G"

S3_SPARK_FILE="/home/ubuntu/matrix_mul_s3.py"
S3_INPUT_A_1000="s3a://tanzima-matrix-data/A_1000.txt"
S3_INPUT_B_1000="s3a://tanzima-matrix-data/B_1000.txt"
S3_OUTPUT_1000="s3a://tanzima-matrix-data/output_1000.json"

EBS_SPARK_FILE="/home/ubuntu/matrix_mul_ebs.py"
EBS_INPUT_A_1000="/home/ubuntu/A_1000.txt"
EBS_INPUT_B_1000="/home/ubuntu/B_1000.txt"
EBS_OUTPUT_1000="/home/ubuntu/output_1000.json"

### ==== FUNCTIONS ==== ###

check_disk_space() {
    FREE=$(df --output=avail -BG / | tail -1 | sed 's/G//')
    echo "Free disk space: ${FREE} GB"

    if (( FREE < MIN_FREE_GB )); then
        echo "WARNING: Low disk space (< ${MIN_FREE_GB}GB)."
        return 1
    fi

    return 0
}

safe_cleanup() {
    echo "Performing SAFE cleanup..."

    sudo rm -rf /tmp/*
    sudo rm -rf /var/tmp/*

    rm -rf ~/.cache/pip
    rm -rf ~/.cache/pyspark

    echo "Cleanup done."
}

run_s3() {
    echo "Running Spark job on S3 (cluster mode)..."

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores $EXECUTOR_CORES \
        --executor-memory $EXECUTOR_MEMORY \
        --driver-memory $DRIVER_MEMORY \
        "$S3_SPARK_FILE" \
        --input_a "$S3_INPUT_A_1000" \
        --input_b "$S3_INPUT_B_1000" \
        --output "$S3_OUTPUT_1000"
}

run_ebs() {
    echo "Running Spark job on EBS (cluster mode)..."
    echo "NOTE: Make sure A_1000.txt and B_1000.txt exist on EVERY worker at the same path."

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores $EXECUTOR_CORES \
        --executor-memory $EXECUTOR_MEMORY \
        --driver-memory $DRIVER_MEMORY \
        "$EBS_SPARK_FILE" \
        --input_a "$EBS_INPUT_A_1000" \
        --input_b "$EBS_INPUT_B_1000" \
        --output "$EBS_OUTPUT_1000"
}

### ==== MAIN LOGIC ==== ###

# Check arg
if [[ "$1" != "1" && "$1" != "2" ]]; then
    echo "Usage:"
    echo "  $0 1    # Run S3 job"
    echo "  $0 2    # Run EBS job"
    exit 1
fi

echo "========== Spark Job Launcher =========="

check_disk_space
if [ $? -ne 0 ]; then
    safe_cleanup

    echo "Rechecking disk space..."
    check_disk_space
    if [ $? -ne 0 ]; then
        echo "ERROR: Still not enough disk space. Exiting."
        exit 1
    fi
fi

# Execute correct job
if [ "$1" == "1" ]; then
    run_s3
elif [ "$1" == "2" ]; then
    run_ebs
fi

echo "Spark Job Finished"


