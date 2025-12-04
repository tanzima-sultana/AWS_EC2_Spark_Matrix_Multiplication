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


MIN_FREE_GB=1

EXECUTOR_MEMORY="10G"
DRIVER_MEMORY="8G"

INPUT_A_1000="s3a://$BUCKET/A_1000.txt"
INPUT_B_1000="s3a://$BUCKET/B_1000.txt"
OUTPUT_1000="s3a://$BUCKET/output_1000.json"

INPUT_A_3000="s3a://$BUCKET/A_3000.txt"
INPUT_B_3000="s3a://$BUCKET/B_3000.txt"
OUTPUT_3000="s3a://$BUCKET/output_3000.json"

INPUT_A_5000="s3a://$BUCKET/A_5000.txt"
INPUT_B_5000="s3a://$BUCKET/B_5000.txt"
OUTPUT_5000="s3a://$BUCKET/output_5000.json"

INPUT_A_8000="s3a://$BUCKET/A_8000.txt"
INPUT_B_8000="s3a://$BUCKET/B_8000.txt"
OUTPUT_8000="s3a://$BUCKET/output_8000.json"

INPUT_A_10000="s3a://$BUCKET/A_10000.txt"
INPUT_B_10000="s3a://$BUCKET/B_10000.txt"
OUTPUT_10000="s3a://$BUCKET/output_10000.json"

# ----- Helper functions

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

## ----- Spark job

run_job() {
    local INPUT_A=$1
    local INPUT_B=$2
    local OUTPUT=$3

    echo "Running Spark job with executor cores = $EXECUTOR_CORES"

    spark-submit \
        --master "$MASTER" \
        --deploy-mode client \
        --packages "$PACKAGES" \
        --conf spark.pyspark.python="$PYTHON_PATH" \
        --executor-cores "$EXECUTOR_CORES" \
        --executor-memory "$EXECUTOR_MEMORY" \
        --driver-memory "$DRIVER_MEMORY" \
        "$SPARK_FILE" \
        --mode "AWS" \
        --input_a "$INPUT_A" \
        --input_b "$INPUT_B" \
        --output "$OUTPUT"
}

# ----- 

# Validate arguments
if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 <matrix_size> <executor_cores>"
    echo "Example: $0 5000 12"
    exit 1
fi

MATRIX_SIZE="$1"
EXECUTOR_CORES="$2"

# Validate matrix size
if [[ "$MATRIX_SIZE" != "1000" && "$MATRIX_SIZE" != "3000" && "$MATRIX_SIZE" != "5000" && "$MATRIX_SIZE" != "8000" && "$MATRIX_SIZE" != "10000" ]]; then
    echo "Invalid matrix size."
    exit 1
fi

# Validate executor cores (must be integer)
if ! [[ "$EXECUTOR_CORES" =~ ^[0-9]+$ ]]; then
    echo "Executor cores must be a number."
    exit 1
fi


echo "Running Spark job.."
echo "Matrix size: $MATRIX_SIZE x $MATRIX_SIZE"
echo "Executor cores: $EXECUTOR_CORES"

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

case $MATRIX_SIZE in
    "1000")  run_job "$INPUT_A_1000" "$INPUT_B_1000" "$OUTPUT_1000" ;;
    "3000")  run_job "$INPUT_A_3000" "$INPUT_B_3000" "$OUTPUT_3000" ;;
    "5000")  run_job "$INPUT_A_5000" "$INPUT_B_5000" "$OUTPUT_5000" ;;
    "8000")  run_job "$INPUT_A_8000" "$INPUT_B_8000" "$OUTPUT_8000" ;;
    "10000") run_job "$INPUT_A_10000" "$INPUT_B_10000" "$OUTPUT_10000" ;;
esac

echo "Spark Job Finished"

