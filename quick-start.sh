#!/bin/bash

# Quick start script for Marker Docker deployment
# This script helps users quickly set up and run the Marker PDF converter

set -e

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m' # No Color

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    log_info "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

log_success "Docker is installed"

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    log_error "Docker Compose is not available. Please install Docker Compose."
    log_info "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

log_success "Docker Compose is available"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    log_info "Creating .env file from template..."
    cp .env.example .env
    log_success ".env file created. You can edit it to add API keys."
else
    log_info ".env file already exists"
fi

# Create necessary directories
log_info "Creating directories for uploads and outputs..."
mkdir -p uploads outputs
log_success "Directories created"

# Ask user if they want to pull the pre-built image or build locally
echo ""
echo "Choose deployment option:"
echo "1) Pull pre-built image from GitHub Container Registry (faster)"
echo "2) Build image locally from source"
echo ""
read -p "Enter your choice (1 or 2, default: 1): " choice
choice=${choice:-1}

if [ "$choice" == "1" ]; then
    log_info "Pulling pre-built image from GitHub Container Registry..."
    if docker pull ghcr.io/gentle-lijie/marker-docker:latest; then
        log_success "Image pulled successfully"
        # Update docker-compose.yml to use the pulled image
        log_info "Starting services with pre-built image..."
        docker run -d \
            -p 8000:8000 \
            --name marker-server \
            -v "$(pwd)/uploads:/app/uploads" \
            -v "$(pwd)/outputs:/app/outputs" \
            --env-file .env \
            ghcr.io/gentle-lijie/marker-docker:latest
    else
        log_warning "Failed to pull pre-built image. Falling back to local build..."
        choice="2"
    fi
fi

if [ "$choice" == "2" ]; then
    log_info "Building Docker image locally (this may take several minutes)..."
    docker compose build
    log_success "Image built successfully"
    
    log_info "Starting services..."
    docker compose up -d
fi

log_success "Marker PDF Server is starting..."

# Wait for the server to be ready
log_info "Waiting for server to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8000/ > /dev/null 2>&1; then
        log_success "Server is ready!"
        break
    fi
    sleep 2
    if [ $i -eq 30 ]; then
        log_warning "Server is taking longer than expected to start."
        log_info "Check logs with: docker logs marker-server"
    fi
done

echo ""
log_success "🎉 Marker PDF Server is running!"
echo ""
echo "Access points:"
echo "  - Home: http://localhost:8000"
echo "  - API Docs: http://localhost:8000/docs"
echo ""
echo "To stop the server:"
if [ "$choice" == "1" ]; then
    echo "  docker stop marker-server"
else
    echo "  docker compose down"
fi
echo ""
echo "To view logs:"
if [ "$choice" == "1" ]; then
    echo "  docker logs -f marker-server"
else
    echo "  docker compose logs -f"
fi
echo ""
