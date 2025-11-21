
#source matrix-env/bin/activate from home

N=8000
BUCKET="<bucket_name>"
python3 generate_input.py --n $N --bucket $BUCKET
