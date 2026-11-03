# Display startup banner
Write-Host "========================================="
Write-Host "Starting FIT3182 Docker Environment"
Write-Host "========================================="
Write-Host ""

# Remove containers from previous runs if they exist
Write-Host "Cleaning up old containers..."
docker rm -f zookeeper mongodb kafka pyspark 2>$null | Out-Null
Write-Host ""

# Remove the Docker network from previous runs if it exists
Write-Host "Removing old Docker network (fit3182-net) if it exists..."
docker network rm fit3182-net 2>$null | Out-Null

# Create a fresh Docker network for container communication
Write-Host "Creating fresh Docker network (fit3182-net)..."
docker network create fit3182-net | Out-Null

Write-Host "Network ready."
Write-Host ""

# ------------------------------------------------------------------
# 1/4 - Start Zookeeper
# Required by Kafka for broker coordination and metadata management
# ------------------------------------------------------------------
Write-Host "[1/4] Starting Zookeeper..."

docker run -d --name zookeeper --network fit3182-net -p 2181:2181 fit3182/zookeeper

# Verify container started successfully
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start Zookeeper"
    exit 1
}

Write-Host "Zookeeper started successfully"

# Allow time for Zookeeper initialization
Start-Sleep -Seconds 10

# ------------------------------------------------------------------
# 2/4 - Start MongoDB
# Stores violation and processed data
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[2/4] Starting MongoDB..."

# Create data directory if it doesn't exist
$mongoData = Join-Path $PWD "mongodb_data"
if (!(Test-Path $mongoData)) {
    New-Item -ItemType Directory -Path $mongoData | Out-Null
}

docker run -d --name mongodb --network fit3182-net -v "${mongoData}:/data/db" -p 27017:27017 fit3182/mongo

# Verify container started successfully
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start MongoDB"
    exit 1
}

Write-Host "MongoDB started successfully"

# Allow time for MongoDB initialization
Start-Sleep -Seconds 5

# ------------------------------------------------------------------
# 3/4 - Start Kafka
# Handles real-time message streaming
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] Starting Kafka..."

docker run -d --name kafka --network fit3182-net -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 -e KAFKA_ADVERTISED_HOST_NAME=kafka -p 9092:9092 fit3182/kafka

# Verify container started successfully
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start Kafka"
    exit 1
}

Write-Host "Kafka started successfully"

# Allow time for Kafka broker initialization
Start-Sleep -Seconds 10

# ------------------------------------------------------------------
# 4/4 - Start PySpark Jupyter Notebook
# Used for Spark streaming and data processing
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[4/4] Starting PySpark Jupyter Notebook..."
Write-Host "Notebook will be available at http://localhost:8888"
Write-Host ""

docker run --name pyspark --network fit3182-net -v "${PWD}:/home/student" -w /home/student/src -p 8888:8888 -p 4040:4040 fit3182/pyspark jupyter notebook --ip=0.0.0.0 --allow-root