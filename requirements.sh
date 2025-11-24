#!/bin/bash

set -e

echo "===== Updating system ====="
sudo apt update && sudo apt upgrade -y

echo "===== Installing Java 17 ====="
sudo apt install -y openjdk-17-jdk

echo "===== Installing Spark 4.0.1 ====="
cd /opt
sudo wget https://downloads.apache.org/spark/spark-4.0.1/spark-4.0.1-bin-hadoop3.tgz
sudo tar -xzf spark-4.0.1-bin-hadoop3.tgz
sudo mv spark-4.0.1-bin-hadoop3 spark
sudo chown -R ubuntu:ubuntu /opt/spark

echo "===== Installing Python venv ====="
sudo apt install -y python3-venv
python3 -m venv ~/pyspark-env

echo "===== Activating venv ====="
source ~/pyspark-env/bin/activate

echo "===== Upgrading pip ====="
pip install --upgrade pip

echo "===== Installing Python dependencies ====="
pip install numpy boto3

echo "===== Configuring ~/.bashrc ====="
cat << 'EOF' >> ~/.bashrc

# Spark & Java paths
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=/opt/spark
export PATH=$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin
export PYSPARK_PYTHON=python3

EOF

echo "===== Installing AWS CLI v2 ====="
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install

echo "===== Installation completed. ====="
echo "Run 'source ~/.bashrc' or start a new terminal session."

