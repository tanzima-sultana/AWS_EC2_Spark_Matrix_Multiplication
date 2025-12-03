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

EC2_HOURLY_COST=0.354

def main():
	# ----- Log file
	log_file = "matrix_log.txt"

	# Delete existing log file if present
	if os.path.exists(log_file):
		os.remove(log_file)

	sys.stdout = open(log_file, "w")

	# ----- Argument parsing
	parser = argparse.ArgumentParser()
	parser.add_argument("--mode", required=True)
	parser.add_argument("--input_a", required=True)
	parser.add_argument("--input_b", required=True)
	parser.add_argument("--output", required=True)
	args = parser.parse_args()

	# ----- Spark session
	app_builder = SparkSession.builder.appName("MatrixMul")
	if args.mode == "local":
		app_builder = app_builder.master("local[*]")

	spark = app_builder.getOrCreate()
	sc = spark.sparkContext

	# Start timer for total time
	total_start_time = time.time()

	# Start timer for input time
	input_start_time = time.time()

	# ----- Load Input A
	rddA = sc.textFile(args.input_a).map(
		lambda line: list(map(float, line.split()))
	)

	firstA = rddA.first()
	num_rows_A = rddA.count()
	num_cols_A = len(firstA)

	print(f"Matrix A: {num_rows_A} x {num_cols_A}")

	# ----- Load Input B
	rddB = sc.textFile(args.input_b).map(
		lambda line: list(map(float, line.split()))
	)

	B = np.array(rddB.collect())
	num_rows_B, num_cols_B = B.shape

	print(f"Matrix B: {num_rows_B} x {num_cols_B}")

	input_end_time = time.time()
	input_time = input_end_time - input_start_time

	# Broadcast B
	B_bcast = sc.broadcast(B)

	# ----- Multiply
	def multiply_row(row):
		arr_row = np.array(row)
		return arr_row.dot(B_bcast.value).tolist()

	result = rddA.map(multiply_row).collect()
	C = np.array(result)

	print(f"Output Matrix C: {C.shape[0]} x {C.shape[1]}")

	# ----- Random check
	for _ in range(3):
		i = random.randint(0, C.shape[0] - 1)
		j = random.randint(0, C.shape[1] - 1)

		Ai = np.array(rddA.take(i + 1)[i])
		expected = np.sum(Ai * B[:, j])

		print(f"Check C[{i},{j}] = {C[i, j]}, expected={expected}")
	
	# Start timer for output time
	output_start_time = time.time()
    
	# ----- Output saved in local
	if args.mode == "local":
		np.savetxt(args.output, C, fmt="%.6f")

	# ----- Output saved in S3
	else:
		# Parse S3 output path
		clean_path = args.output.replace("s3a://", "", 1)
		bucket = clean_path.split("/")[0]
		key = "/".join(clean_path.split("/")[1:])

		# Save JSON
		with tempfile.NamedTemporaryFile(delete=False, mode="w") as tmp:
			for row in C:
				tmp.write(json.dumps(row.tolist()) + "\n")
				local_file = tmp.name
				
		# Upload to S3
		s3 = boto3.client("s3")
		s3.upload_file(local_file, bucket, key)

		print("Saved output to S3.")

	output_end_time = time.time()
	output_time = output_end_time - output_start_time

	# Runtime
	total_end_time = time.time()
	elapsed_sec = total_end_time - total_start_time

	print(f"Total runtime: {elapsed_sec:.3f} seconds, Input read time: {input_time:.3f} seconds, Output write time: {output_time:.3f} seconds")

	# AWS cost
	if args.mode == "AWS":
		cost = (elapsed_sec / 3600.0) * EC2_HOURLY_COST
		print(f"Approx EC2 Cost (on-demand): ${cost:.6f}")

	spark.stop()
	sys.stdout.close()


if __name__ == "__main__":
	main()

