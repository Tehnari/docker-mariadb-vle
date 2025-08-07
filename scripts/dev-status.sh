#!/bin/bash

echo "📊 Checking MariaDB Development Environment Status..."

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

# Show container status
echo "🔍 Container Status:"
$DOCKER_COMPOSE_CMD ps

echo ""
echo "📈 Service Health:"
$DOCKER_COMPOSE_CMD ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

