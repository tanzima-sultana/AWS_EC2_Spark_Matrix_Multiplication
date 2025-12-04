
#source matrix-env/bin/activate from home

#!/bin/bash

# --- Validate argument ---
if [ -z "$1" ]; then
    echo "Usage: $0 <matrix_size>"
    echo "Example: $0 1000"
    exit 1
fi

INPUT_DIR="./Input"
INPUT_A="$INPUT_DIR/A_${MATRIX_SIZE}.txt"
INPUT_B="$INPUT_DIR/B_${MATRIX_SIZE}.txt"

MODE="AWS"
BUCKET=$BUCKET
N=$1


echo "Generating input matrix of size ${N}x${N} and uploading to bucket: $BUCKET"

python3 generate_input.py --mode "$MODE" --bucket "$BUCKET" --input_a "$INPUT_A" --input_a "$INPUT_A" --n "$N" 

