#!/bin/bash

echo "🚀 Starting MariaDB Development Environment..."

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Check for docker compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

# Start services
$DOCKER_COMPOSE_CMD up -d

echo "✅ Development environment should be ready!"
