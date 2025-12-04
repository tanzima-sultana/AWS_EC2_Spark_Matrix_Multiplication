# AWS EC2 Spark Matrix Multiplication

This project performs matrix multiplication using PySpark on a standalone Spark cluster running on AWS EC2 (1 master, 2 workers). Matrices are stored in Amazon S3, processed using Spark RDD operations, and results are written back to S3.

The main goals of this work are to:

- run a complete end-to-end distributed workload on EC2  
- automate cluster setup, environment configuration, and deployment  
- benchmark matrix sizes up to 10,000 × 10,000  
- measure how executor cores, cluster size, and partitioning affect runtime  

The repository includes a GitHub CI pipeline and automation scripts for cluster setup and running the Spark job.

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

**Programming & Libraries**
- Python 3.x
- NumPy
- Boto3 (AWS SDK for Python)

**Automation & Tooling**
- GitHub CI pipeline for validation and lint checks
- `config.env`-based configuration for consistent deployment
- Automated project sync from local → EC2 master
- SSH scripts for starting/stopping Spark master & workers
- Environment setup script (`requirements.sh`)
- Cluster setup instructions

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
- GitHub Actions CI pipeline for basic validation

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

## Repository Structure
```
/
├── Input/
│ ├── generate_input.py
│ ├── input.sh
├── config.env.template
├── matrix_mul.py
├── aws.sh
├── local_run.sh
├── dist_run.sh
├── ec2_cluster_start.sh
├── ec2_cluster_stop.sh
├── requirements.sh
├── cluster_setup.txt
├── README.md
```

---

## Installation
Clone the repository:
```bash
git clone https://github.com/tanzima-sultana/AWS_EC2_Spark_Matrix_Multiplication.git
cd AWS_EC2_Spark_Matrix_Multiplication
```

Fillout config.env:
```bash
cp config.env.template config.env
```

Follow cluster_setup.txt for AWS EC2 cluster setup instructions.

Install dependencies:
```bash
chmod +x requirements.sh
./requirements.sh

```

---

## How to Run

### 1. Generate input and upload to S3
From the `Input/` directory:
```bash
cd Input
./input.sh <matrix_size>
```

### 3. Run on local machine (runs a small 100x100 matrix multiplication)
```bash
./local_run.sh
```

### 4. Copy project and SSH to master node
Update Master EC2 public IP in config.env
```bash
./aws.sh
```

### 5. Start the EC2 Spark cluster (on Master EC2)
```bash
./ec2_cluster_start.sh
```

### 6. Run the Spark job
```bash
./dist_run.sh <matrix_size> <executor_cores>
```

### 7. Check logs and output
- Runtime log:  
  `/home/ubuntu/matrix_log.txt`

- Output matrix is saved in your S3 bucket under the `output/` folder.

### 8. Stop the EC2 Spark cluster
```bash
./ec2_cluster_stop.sh
```

### 8. Git push and CI action
Push updates and view CI status under the Actions tab in GitHub.


