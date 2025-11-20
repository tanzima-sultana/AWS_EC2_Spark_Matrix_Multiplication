#!/usr/bin/env python3
import argparse
import numpy as np
import boto3
import os
import tempfile


def generate_matrix(n, file_path):
    """
    Creates an n x n matrix with random floats and writes it to file_path.
    Each row is written as space-separated values.
    """
    with open(file_path, "w") as f:
        for _ in range(n):
            row = np.random.rand(n)
            line = " ".join(f"{x:.6f}" for x in row)
            f.write(line + "\n")


def upload_to_s3(local_path, bucket_name, key_name):
    """
    Uploads a local file to s3://bucket_name/key_name
    """
    s3 = boto3.client("s3")
    print(f"Uploading {local_path} → s3://{bucket_name}/{key_name} ...")
    s3.upload_file(local_path, bucket_name, key_name)
    print(f"Uploaded successfully: s3://{bucket_name}/{key_name}")


def main():
    parser = argparse.ArgumentParser(description="Generate NxN matrices A and B and upload to S3.")
    parser.add_argument("--n", type=int, required=True, help="Matrix size (N for NxN)")
    parser.add_argument("--bucket", type=str, required=True, help="S3 bucket name")
    args = parser.parse_args()

    n = args.n
    bucket = args.bucket

    # File names
    A_key = f"A_{n}.txt"
    B_key = f"B_{n}.txt"

    # Create a temp directory to store the files before upload
    with tempfile.TemporaryDirectory() as tmpdir:
        A_local = os.path.join(tmpdir, A_key)
        B_local = os.path.join(tmpdir, B_key)

        print(f"Generating A ({n}x{n}) → {A_local}")
        generate_matrix(n, A_local)

        print(f"Generating B ({n}x{n}) → {B_local}")
        generate_matrix(n, B_local)

        upload_to_s3(A_local, bucket, A_key)
        upload_to_s3(B_local, bucket, B_key)

    print("\nAll done!")
    print("Use these paths in Spark:")
    print(f"  A: s3a://{bucket}/{A_key}")
    print(f"  B: s3a://{bucket}/{B_key}")


if __name__ == "__main__":
    main()

