
#source matrix-env/bin/activate from home

#!/bin/bash

# --- Validate argument ---
if [ -z "$1" ]; then
    echo "Usage: $0 <matrix_size>"
    echo "Example: $0 1000"
    exit 1
fi

N=$1
BUCKET="<bucket_name>"

echo "Generating input matrix of size ${N}x${N} and uploading to bucket: $BUCKET"

python3 generate_input.py --n "$N" --bucket "$BUCKET"

