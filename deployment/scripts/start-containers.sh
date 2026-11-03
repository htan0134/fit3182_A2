#!/bin/bash

# Display startup banner
echo "========================================="
echo "Starting FIT3182 Docker Environment"
echo "========================================="

echo ""

# Remove any existing containers from a previous run
echo "Cleaning up old containers..."
docker rm -f zookeeper mongodb kafka pyspark 2>/dev/null

echo ""

# Remove the Docker network if it already exists
echo "Removing old Docker network (fit3182-net) if it exists..."
docker network rm fit3182-net 2>/dev/null

echo ""

# Create a fresh Docker network for container communication
echo "Creating fresh Docker network (fit3182-net)..."
docker network create fit3182-net >/dev/null

# Check whether network creation was successful
if [ $? -ne 0 ]; then
    echo "Failed to create Docker network"
    exit 1
fi

echo "Network ready."
echo ""

# ------------------------------------------------------------------
# 1/4 - Start Zookeeper
# Required by Kafka for broker coordination and metadata management
# ------------------------------------------------------------------
echo "[1/4] Starting Zookeeper..."
docker run -d \
    --name zookeeper \
    --network fit3182-net \
    -p 2181:2181 \
    fit3182/zookeeper

# Verify container started successfully
if [ $? -ne 0 ]; then
    echo "Failed to start Zookeeper"
    exit 1
fi

echo "Zookeeper started successfully"

# Allow time for Zookeeper to initialize
sleep 10

# ------------------------------------------------------------------
# 2/4 - Start MongoDB
# Stores violation records and processed data
# ------------------------------------------------------------------
echo ""
echo "[2/4] Starting MongoDB..."
docker run -d \
    --name mongodb \
    --network fit3182-net \
    -v "$(pwd)/mongodb_data:/data/db" \
    -p 27017:27017 \
    fit3182/mongo

# Verify container started successfully
if [ $? -ne 0 ]; then
    echo "Failed to start MongoDB"
    exit 1
fi

echo "MongoDB started successfully"

# Allow time for MongoDB to initialize
sleep 5

# ------------------------------------------------------------------
# 3/4 - Start Kafka
# Handles streaming data between producers and consumers
# ------------------------------------------------------------------
echo ""
echo "[3/4] Starting Kafka..."
docker run -d \
    --name kafka \
    --network fit3182-net \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_HOST_NAME=kafka \
    -p 9092:9092 \
    fit3182/kafka

# Verify container started successfully
if [ $? -ne 0 ]; then
    echo "Failed to start Kafka"
    exit 1
fi

echo "Kafka started successfully"

# Allow time for Kafka broker startup
sleep 5

# ------------------------------------------------------------------
# 4/4 - Start PySpark Jupyter Notebook
# Used for Spark streaming and data processing tasks
# ------------------------------------------------------------------
echo ""
echo "[4/4] Starting PySpark Jupyter Notebook..."
echo "Notebook will be available at http://localhost:8888"
echo ""

docker run --name pyspark \
    --network fit3182-net \
    -v "$(pwd):/home/student" \
    -w /home/student/src \
    -p 8888:8888 \
    -p 4040:4040 \
    fit3182/pyspark \
    jupyter notebook --ip=0.0.0.0 --allow-root

# --name pyspark
#   Assigns a fixed container name for easier management.
#
# --network fit3182-net
#   Connects the container to the shared Docker network so it can
#   communicate with Kafka, MongoDB, and Zookeeper.
#
# -v "$(pwd):/home/student"
#   Mounts the current project directory into the container.
#   Changes made locally are immediately visible inside the container.
#
# -w /home/student/src
#   Sets the container's working directory when it starts.
#
# -p 8888:8888
#   Exposes the Jupyter Notebook web interface.
#
# -p 4040:4040
#   Exposes the Spark UI for monitoring Spark jobs.
#
# jupyter notebook --ip=0.0.0.0 --allow-root
#   Starts Jupyter Notebook and allows access from outside
#   the container.