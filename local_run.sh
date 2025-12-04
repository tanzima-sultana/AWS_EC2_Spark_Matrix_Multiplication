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


MATRIX_SIZE=100

INPUT_DIR="./Input"
INPUT_A="$INPUT_DIR/A_${MATRIX_SIZE}.txt"
INPUT_B="$INPUT_DIR/B_${MATRIX_SIZE}.txt"
OUTPUT="output_${MATRIX_SIZE}.txt"

BUCKET="none"

# ----- 
# ----- activate virtualenv
# ----- 
echo "Activate Python virtualenv ..."

source "${PY_ENV_LOCAL}/bin/activate"


# ----- 
# ----- Generate 100x100 input matrices and save in local machine
# ----- 
echo "Generating ${MATRIX_SIZE}x${MATRIX_SIZE} input matrices..."

# ----- Generate input
${PYTHON} ./Input/generate_input.py \
    --mode "local" \
    --bucket $BUCKET \
    --input_a $INPUT_A \
    --input_b $INPUT_B \
    --n ${MATRIX_SIZE}


# ----- 
# ----- Run PySpark job in LOCAL mode
# ----- 
echo "Running PySpark job in local mode for ${MATRIX_SIZE}x${MATRIX_SIZE}..."

rm -f "${OUTPUT}"

spark-submit \
  --master local[*] \
  --deploy-mode client \
  matrix_mul.py \
  --mode "local" \
  --input_a "${INPUT_A}" \
  --input_b "${INPUT_B}" \
  --output "${OUTPUT}"


echo "PySpark job finished. Output written to: ${OUTPUT}"


