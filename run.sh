#!/bin/bash

### ==== CONFIG ==== ###
MIN_FREE_GB=1       # Require at least 1 GB free
PYTHON_PATH="/home/ubuntu/pyspark-env/bin/python"

# Spark standalone cluster master (private IP of master)
MASTER="spark://<master_private_ip>:7077"

PACKAGES="org.apache.spark:spark-hadoop-cloud_2.13:4.0.1"

EXECUTOR_CORES=6
EXECUTOR_MEMORY="10G"
DRIVER_MEMORY="8G"

SPARK_FILE="/home/ubuntu/Spark_Matrix_Mul/matrix_mul.py"

INPUT_A_1000="s3a://<bucket_name>/A_1000.txt"
INPUT_B_1000="s3a://<bucket_name>/B_1000.txt"
OUTPUT_1000="s3a://<bucket_name>/output_1000.json"

INPUT_A_3000="s3a://<bucket_name>/A_3000.txt"
INPUT_B_3000="s3a://<bucket_name>/B_3000.txt"
OUTPUT_3000="s3a://<bucket_name>/output_3000.json"

INPUT_A_5000="s3a://<bucket_name>/A_5000.txt"
INPUT_B_5000="s3a://<bucket_name>/B_5000.txt"
OUTPUT_5000="s3a://<bucket_name>/output_5000.json"

INPUT_A_8000="s3a://<bucket_name>/A_8000.txt"
INPUT_B_8000="s3a://<bucket_name>/B_8000.txt"
OUTPUT_8000="s3a://<bucket_name>/output_8000.json"

INPUT_A_10000="s3a://<bucket_name>/A_10000.txt"
INPUT_B_10000="s3a://<bucket_name>/B_10000.txt"
OUTPUT_10000="s3a://<bucket_name>/output_10000.json"

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

run_1000() {
    echo "Running Spark job..."

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores $EXECUTOR_CORES \
        --executor-memory $EXECUTOR_MEMORY \
        --driver-memory $DRIVER_MEMORY \
        "$SPARK_FILE" \
        --input_a "$INPUT_A_1000" \
        --input_b "$INPUT_B_1000" \
        --output "$OUTPUT_1000"
}

run_3000() {
    echo "Running Spark job..."

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores $EXECUTOR_CORES \
        --executor-memory $EXECUTOR_MEMORY \
        --driver-memory $DRIVER_MEMORY \
        "$SPARK_FILE" \
        --input_a "$INPUT_A_3000" \
        --input_b "$INPUT_B_3000" \
        --output "$OUTPUT_3000"
}

run_5000() {
    echo "Running Spark job..."

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores $EXECUTOR_CORES \
        --executor-memory $EXECUTOR_MEMORY \
        --driver-memory $DRIVER_MEMORY \
        "$SPARK_FILE" \
        --input_a "$INPUT_A_5000" \
        --input_b "$INPUT_B_5000" \
        --output "$OUTPUT_5000"
}

run_8000() {
    echo "Running Spark job..."

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores $EXECUTOR_CORES \
        --executor-memory $EXECUTOR_MEMORY \
        --driver-memory $DRIVER_MEMORY \
        "$SPARK_FILE" \
        --input_a "$INPUT_A_8000" \
        --input_b "$INPUT_B_8000" \
        --output "$OUTPUT_8000"
}

run_10000() {
    echo "Running Spark job..."

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores $EXECUTOR_CORES \
        --executor-memory $EXECUTOR_MEMORY \
        --driver-memory $DRIVER_MEMORY \
        "$SPARK_FILE" \
        --input_a "$INPUT_A_10000" \
        --input_b "$INPUT_B_10000" \
        --output "$OUTPUT_10000"
}

### ==== MAIN LOGIC ==== ###

# Check arg
if [[ "$1" != "1000" && "$1" != "3000" && "$1" != "5000" && "$1" != "8000" && "$1" != "10000" ]]; then
    echo "Usage:"
    echo "  $0 1000    # Run using input 1000x1000"
    echo "  $0 3000    # Run using input 3000x3000"
    echo "  $0 5000    # Run using input 5000x5000"
    echo "  $0 8000    # Run using input 8000x8000"
    echo "  $0 10000    # Run using input 10000x10000"
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

# Execute job
if [ "$1" == "1000" ]; then
    run_1000
elif [ "$1" == "3000" ]; then
    run_3000
elif [ "$1" == "5000" ]; then
    run_5000
elif [ "$1" == "8000" ]; then
    run_8000
elif [ "$1" == "10000" ]; then
    run_10000
fi

echo "Spark Job Finished"


