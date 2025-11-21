# DistSparkMatMul
### Distributed Matrix Multiplication Using Apache Spark on AWS EC2 + S3

This project implements large-scale **matrix multiplication using PySpark**, deployed on a **3-node AWS EC2 cluster** (1 master, 2 workers).  
The system reads matrix blocks from S3 or EBS, performs distributed computation using Spark RDD operations, and writes the output back to storage.

The goal is to evaluate how cluster size, executor cores, and partition configuration affect performance for different matrix sizes.

---

## 🚀 Project Features
- Distributed matrix multiplication using **PySpark RDDs**
- Cluster setup automation scripts for AWS EC2
- Input matrix generator and upload helper (S3 or EBS)
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

## 📊 Performance Summary (c5.2xlarge × 2 workers)

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

**Observation:**  
Higher executor core count (12 cores) consistently improves runtime due to increased parallelism.

---

## 📁 Repository Structure
/
├── Input/
│   ├── generate_input.py
│   ├── input.sh
│
├── matrix_mul.py
├── run.sh
├── ec2_cluster_start.sh
├── ec2_cluster_stop.sh
├── README.md

