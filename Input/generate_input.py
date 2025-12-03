#!/usr/bin/env python3
import argparse
import numpy as np
import boto3
import os
import tempfile


def generate_matrix(n, file_path):

    # Creates an n x n matrix with random floats and writes it to file_path.
    # Each row is written as space-separated values.
    
    print(file_path)
    with open(file_path, "w") as f:
        for _ in range(n):
            row = np.random.rand(n)
            line = " ".join(f"{x:.6f}" for x in row)
            f.write(line + "\n")


def upload_to_s3(local_path, bucket_name, key_name):
    
    # Uploads a local file to s3://bucket_name/key_name
    
    s3 = boto3.client("s3")
    s3.upload_file(local_path, bucket_name, key_name)


def main():

    # ----- Parse args
    parser = argparse.ArgumentParser(description="Generate NxN matrices A and B")
    parser.add_argument("--mode", type=str, required=True, help="Local or Cloud mode")
    parser.add_argument("--bucket", type=str, required=True, help="For AWS bucket name. For local, its none")
    parser.add_argument("--input_a", type=str, required=True, help="Input A file path")
    parser.add_argument("--input_b", type=str, required=True, help="Input B file path")
    parser.add_argument("--n", type=int, required=True, help="Matrix size (n for nxn)")
    args = parser.parse_args()
    
    mode = args.mode
    bucket = args.bucket
    input_a = args.input_a
    input_b = args.input_b
    n = args.n
    

    # ----- Create a temp local directory to store the files 
    with tempfile.TemporaryDirectory() as tmpdir:

        generate_matrix(n, input_a)
        generate_matrix(n, input_b)
        if mode == "aws":
        	# first param input_a = local file path
        	# last param input_a = bucket key
        	# bucket = bucket name
        	# upload_to_s3(local_path, bucket_name, key_name)
        	upload_to_s3(input_a, input_dir, input_a)
        	upload_to_s3(input_b, input_dir, input_b)

if __name__ == "__main__":
    main()

