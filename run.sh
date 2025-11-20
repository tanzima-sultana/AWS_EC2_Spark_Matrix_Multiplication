#!/bin/bash

### ==== CONFIG ==== ###
MIN_FREE_GB=1       # Require at least 1 GB free
PYTHON_PATH="/home/ubuntu/pyspark-env/bin/python"
MASTER="local[2]"
PACKAGES="org.apache.spark:spark-hadoop-cloud_2.13:4.0.1"

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
    echo "Running Spark job on S3..."

    spark-submit \
        --master "$MASTER" \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        "$S3_SPARK_FILE" \
        --input_a "$S3_INPUT_A_1000" \
        --input_b "$S3_INPUT_B_1000" \
        --output "$S3_OUTPUT_1000"
}

run_ebs() {
    echo "Running Spark job on EBS..."

    spark-submit \
        --master "$MASTER" \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
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

