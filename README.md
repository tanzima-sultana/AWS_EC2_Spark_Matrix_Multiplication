# AWS EC2 Spark Matrix Multiplication

This project implements large-scale matrix multiplication using PySpark and deployed on an AWS EC2 cluster (1 master, 2 workers). 
The system reads matrix blocks from S3, performs distributed computation using Spark RDD operations, and writes the output back to storage.
It demonstrates scalable computation, cluster automation, and performance benchmarking across large matrix sizes up to 10,000 × 10,000.
The goal is to evaluate how cluster size, executor cores, and partition configuration affect performance for different matrix sizes.

---

## Tech Stack

**Cloud & Infrastructure**
- AWS EC2 (Standalone Spark Cluster)
- AWS S3 for input/output storage
- IAM Role-based access for S3 operations
- Ubuntu 20.04/22.04 Linux environment

**Distributed Computing**
- Apache Spark 4.x (Standalone Mode)
- PySpark RDD API (map, flatMap, reduceByKey)
- Multi-node execution (1 Master, N Workers)
- Cluster automation with Bash scripts

**Programming & Libraries**
- Python 3.x
- NumPy
- Boto3 (AWS SDK for Python)

**DevOps & Tooling**
- SSH automation (remote worker start/stop)
- Custom `requirements.sh` for full environment setup
- Cluster provisioning instructions (`cluster_setup.txt`)
- Logging & benchmarking utilities

---

## Features
- Distributed matrix multiplication using PySpark RDDs
- Cluster setup scripts for AWS EC2
- Input matrix generator and upload helper (S3)
- Benchmarks for matrix sizes:
  - 1000 × 1000
  - 3000 × 3000
  - 5000 × 5000
  - 8000 × 8000
  - 10000 × 10000
- Performance comparison between:
  - 6 executor cores
  - 12 executor cores

---

## Performance Summary (c5.2xlarge × 2 workers)

| Input Size     | Executor Cores | Input Read (s) | Output Write (s) | Total Runtime (s) |
|----------------|----------------|----------------|------------------|-------------------|
| 1000×1000      | 6              | 17.34          | 0.73             | 22.32             |
|                | 12             | 17.59          | 0.98             | 21.93             |
| 3000×3000      | 6              | 20.70          | 1.70             | 44.56             |
|                | 12             | 20.28          | 1.73             | 42.18             |
| 5000×5000      | 6              | 22.97          | 3.66             | 81.78             |
|                | 12             | 23.51          | 3.73             | 73.64             |
| 8000×8000      | 6              | 30.63          | 8.15             | 195.40            |
|                | 12             | 30.74          | 7.97             | 162.53            |
| 10000×10000    | 6              | 37.06          | 12.37            | 291.28            |
|                | 12             | 35.89          | 12.14            | 255.05            |

Higher executor core count (12 cores) consistently improves total runtime due to increased parallelism.
Larger matrix sizes also show significantly better performance when using higher executor cores.

---

## Installation
Clone the repository:
```bash
git clone https://github.com/<your-username>/DistSparkMatMul.git
cd AWS EC2 Spark Matrix Multiplication
```
Follow cluster_setup.txt for AWS EC2 cluster setup instructions.

Install dependencies:
```bash
chmod +x requirements.sh
./requirements.sh

```

---

## Repository Structure
```
/
├── Input/
│ ├── generate_input.py
│ ├── input.sh
│
├── matrix_mul.py
├── run.sh
├── ec2_cluster_start.sh
├── ec2_cluster_stop.sh
├── requirements.sh
├── cluster_setup.txt
├── README.md
```

---

## How to Run

### 1. Generate input and upload to S3
From the `Input/` directory:
```bash
cd Input
./input.sh <matrix_size>
```

### 2. Start the EC2 Spark cluster
```bash
./ec2_cluster_start.sh
```

### 3. Run the Spark job
```bash
./run.sh <matrix_size> <executor_cores>
```

### 4. Check logs and output
- Runtime log:  
  `/home/ubuntu/matrix_log.txt`

- Output matrix is saved in your S3 bucket under the `output/` folder.

### 5. Stop the EC2 Spark cluster
```bash
./ec2_cluster_stop.sh
```


