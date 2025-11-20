import argparse
import json
import os
import sys
import time
import random
import tempfile
import urllib.request

import boto3
import numpy as np
from pyspark.sql import SparkSession

EC2_HOURLY_COST=0.0416

'''
import urllib.request
import urllib.error

METADATA_BASE = "http://169.254.169.254"


def _get_metadata(path):
    """
    Generic helper for EC2 instance metadata.
    Works with IMDSv2 (token) and falls back to IMDSv1 if needed.
    """
    token = None

    # Try to get IMDSv2 token
    try:
        req = urllib.request.Request(
            METADATA_BASE + "/latest/api/token",
            method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
        )
        with urllib.request.urlopen(req, timeout=2) as r:
            token = r.read().decode()
    except Exception:
        # IMDSv2 token failed -> might be IMDSv1 or metadata disabled
        token = None

    headers = {}
    if token:
        headers["X-aws-ec2-metadata-token"] = token

    try:
        req = urllib.request.Request(
            METADATA_BASE + "/latest/meta-data/" + path,
            headers=headers,
        )
        with urllib.request.urlopen(req, timeout=2) as r:
            return r.read().decode().strip()
    except Exception:
        return None


def get_instance_type():
    return _get_metadata("instance-type")


def get_region():
    # First try the direct region endpoint (IMDSv2+)
    region = _get_metadata("placement/region")
    if region:
        return region

    # Fallback: derive from availability zone (e.g. us-west-2a -> us-west-2)
    az = _get_metadata("placement/availability-zone")
    if az and len(az) > 1:
        return az[:-1]
    return None


def get_ec2_price(instance_type, region):
    """
    Look up on-demand Linux hourly price for this instance/region
    using AWS Pricing API. No hardcoded prices.
    """

    # Map EC2 region code -> Pricing "location" name
    region_map = {
        "us-east-1": "US East (N. Virginia)",
        "us-east-2": "US East (Ohio)",
        "us-west-2": "US West (Oregon)",
        "eu-west-1": "EU (Ireland)",
    }

    location = region_map.get(region)
    if not location:
        print(f"[Pricing] Region {region} not in region_map.")
        return None

    if not instance_type:
        print("[Pricing] instance_type is None.")
        return None

    try:
        pricing = boto3.client("pricing", region_name="us-east-1")

        response = pricing.get_products(
            ServiceCode="AmazonEC2",
            Filters=[
                {"Type": "TERM_MATCH", "Field": "instanceType", "Value": instance_type},
                {"Type": "TERM_MATCH", "Field": "location", "Value": location},
                {"Type": "TERM_MATCH", "Field": "operatingSystem", "Value": "Linux"},
                {"Type": "TERM_MATCH", "Field": "tenancy", "Value": "Shared"},
                {"Type": "TERM_MATCH", "Field": "preInstalledSw", "Value": "NA"},
                # NOTE: capacitystatus filter removed to avoid over-filtering
            ],
            MaxResults=1,
        )
    except Exception as e:
        print(f"[Pricing] Error calling get_products: {e}")
        return None

    price_list = response.get("PriceList", [])
    if not price_list:
        print(
            f"[Pricing] No products returned for instance={instance_type}, "
            f"region={region}, location={location}"
        )
        return None

    try:
        price_item = json.loads(price_list[0])
        terms = price_item["terms"]["OnDemand"]
        term_id = next(iter(terms))
        price_dimensions = terms[term_id]["priceDimensions"]
        dim_id = next(iter(price_dimensions))
        price_per_hour = float(price_dimensions[dim_id]["pricePerUnit"]["USD"])
        return price_per_hour
    except Exception as e:
        print(f"[Pricing] Error parsing price response: {e}")
        return None
'''

def main():
    # -----------------------------
    # Log file setup (local on EC2)
    # -----------------------------
    log_file = "/home/ubuntu/matrix_log_ebs.txt"

    # Delete existing log file if present
    if os.path.exists(log_file):
        os.remove(log_file)

    # Redirect all prints to log file
    sys.stdout = open(log_file, "w")

    # -----------------------------
    # Argument parsing
    # -----------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_a", required=True, help="Path to local matrix A file (on EBS)")
    parser.add_argument("--input_b", required=True, help="Path to local matrix B file (on EBS)")
    parser.add_argument("--output", required=True, help="Path to local output file (on EBS)")
    args = parser.parse_args()

    # -----------------------------
    # Spark session
    # -----------------------------
    spark = (
        SparkSession.builder
        .appName("MatrixMulEBS")
        .getOrCreate()
    )
    sc = spark.sparkContext

    # Start timer after Spark + setup
    start_time = time.time()

    # -------------------------------------
    # Load A from local file (EBS)
    # -------------------------------------
    # Use file:// scheme for explicit local FS, or just args.input_a
    rddA = sc.textFile(args.input_a).map(
        lambda line: list(map(float, line.split()))
    )

    firstA = rddA.first()
    num_rows_A = rddA.count()
    num_cols_A = len(firstA)

    print(f"Matrix A: {num_rows_A} x {num_cols_A}")

    # -------------------------------------
    # Load B from local file (EBS)
    # -------------------------------------
    rddB = sc.textFile(args.input_b).map(
        lambda line: list(map(float, line.split()))
    )

    B = np.array(rddB.collect())
    num_rows_B, num_cols_B = B.shape

    print(f"Matrix B: {num_rows_B} x {num_cols_B}")

    # -------------------------------------
    # Broadcast B
    # -------------------------------------
    B_bcast = sc.broadcast(B)

    # -------------------------------------
    # Multiply
    # -------------------------------------
    def multiply_row(row):
        arr_row = np.array(row)
        return arr_row.dot(B_bcast.value).tolist()

    result = rddA.map(multiply_row).collect()
    C = np.array(result)

    print(f"Output Matrix C: {C.shape[0]} x {C.shape[1]}")

    # -------------------------------------
    # Verify correctness (3 random checks)
    # -------------------------------------
    for _ in range(3):
        i = random.randint(0, C.shape[0] - 1)
        j = random.randint(0, C.shape[1] - 1)

        Ai = np.array(rddA.take(i + 1)[i])
        expected = np.sum(Ai * B[:, j])

        print(f"Check C[{i},{j}] = {C[i, j]}, expected={expected}")

    # -------------------------------------
    # Save output locally on EBS
    # -------------------------------------
    output_path = args.output

    # Write JSON-lines format: one row per line
    with open(output_path, "w") as f_out:
        for row in C:
            f_out.write(json.dumps(row.tolist()) + "\n")

    print(f"Saved output matrix to local file: {output_path}")

    # -------------------------------------
    # Timing and cost
    # -------------------------------------
    end_time = time.time()
    elapsed_sec = end_time - start_time

    print(f"Execution Time: {elapsed_sec:.3f} seconds")
    
    cost = (elapsed_sec / 3600.0) * EC2_HOURLY_COST
    
    print(f"Approx EC2 Cost (on-demand): ${cost:.6f}")

    spark.stop()
    sys.stdout.close()


if __name__ == "__main__":
    main()

