Distributed Matrix Multiplication Using Apache Spark on AWS EC2 + S3

This project implements large-scale matrix multiplication using PySpark, deployed on a 3-node AWS EC2 cluster (1 master, 2 workers). The system reads matrix blocks from S3 or EBS, performs distributed computation using Spark RDD operations, and writes the output back to storage.

The goal is to evaluate how cluster size, executor cores, and partition configuration affect performance for different matrix sizes.

🚀 Project Features

Distributed matrix multiplication using PySpark RDDs

Cluster setup scripts for AWS EC2

Input matrix generator and S3 upload helper

Benchmarking across large matrices:

1000 × 1000

3000 × 3000

5000 × 5000

8000 × 8000

10000 × 10000

Performance comparison for:

6 executor cores

12 executor cores

Clean, reusable scripts for automation

📊 Performance Summary (c5.2xlarge × 2 workers)
Input Size	Executor Cores	Input Read (s)	Output Write (s)	Total Runtime (s)
1000×1000	6	17.34	0.73	22.32
	12	17.59	0.98	21.93
3000×3000	6	20.70	1.70	44.56
	12	20.28	1.73	42.18
5000×5000	6	22.97	3.66	81.78
	12	23.51	3.73	73.64
8000×8000	6	30.63	8.15	195.40
	12	30.74	7.97	162.53
10000×10000	6	37.06	12.37	291.28
	12	35.89	12.14	255.05

Observation:
Higher executor core count (12) consistently reduces computation runtime due to increased parallelism.

📁 Repository Structure
/
├── Input/
│   ├── generate_input.py      # Generates random matrices
│   ├── input.sh               # Upload to S3 or save to EBS
│
├── matrix_mul.py              # Distributed matrix multiplication
├── run.sh                     # Main execution script
├── ec2_cluster_start.sh       # Launch EC2 cluster (sanitized)
├── ec2_cluster_stop.sh        # Stop/terminate nodes
├── README.md

⚙️ How to Run
1️⃣ Generate matrices
cd Input
python3 generate_input.py --size 5000 --output matrixA_5000.txt
python3 generate_input.py --size 5000 --output matrixB_5000.txt

2️⃣ Upload to S3 (optional)
bash input.sh

3️⃣ Submit Spark job
bash run.sh 5000

🏗 Cluster Setup (EC2)

This project uses:

1 master + 2 worker nodes

Instance type: c5.2xlarge (8 vCPU, 16 GB RAM)

Spark standalone cluster

Storage options:

S3

EBS local SSD

Scripts:

ec2_cluster_start.sh – Start cluster, install dependencies

ec2_cluster_stop.sh – Stop all nodes gracefully
