# Docker Setup Summary

This document provides a summary of the Docker containerization setup added to the Marker PDF project.

## Overview

This PR adds complete Docker containerization support, enabling users to deploy the Marker PDF converter with a single command. The implementation includes automated building and publishing to GitHub Container Registry.

## What Was Added

### 1. Core Docker Files

#### `Dockerfile`
- Based on Python 3.11 slim image for optimal size
- Multi-layer build with dependency caching
- Installs Poetry for dependency management
- Supports both CPU and GPU (CUDA) environments
- Includes health check for container monitoring
- Exposes port 8000 for the FastAPI server
- Uses custom entrypoint script for initialization

#### `.dockerignore`
- Optimizes build context by excluding unnecessary files
- Reduces build time and final image size
- Excludes: .git, cache directories, test data, documentation (except README.md)

#### `docker-compose.yml`
- Simplified deployment with single command
- Configures port mapping (8000:8000)
- Sets up volume mounts for uploads and outputs
- Environment variable configuration
- Includes commented GPU support configuration
- Uses restart policy for high availability

#### `docker-entrypoint.sh`
- Initialization script for container startup
- Logs startup information
- Provides flexible execution of main command

### 2. Automation and CI/CD

#### `.github/workflows/docker-publish.yml`
- Automated Docker image building on push to main/master
- Triggers on version tags (e.g., v1.0.0)
- Publishes to GitHub Container Registry (ghcr.io)
- Multi-tag strategy: version tags, major.minor, major, latest
- Uses Docker Buildx for advanced features
- Implements layer caching for faster builds
- Supports manual workflow dispatch

### 3. User Tools

#### `quick-start.sh`
- Interactive setup script with colored output
- Checks Docker installation
- Creates necessary directories
- Offers choice between pre-built image or local build
- Automatically starts the server
- Provides helpful next-step instructions
- Includes health check with 30-second timeout

#### `.env.example`
- Template for environment configuration
- Documents all available options:
  - TORCH_DEVICE (cpu, cuda, mps)
  - API keys for LLM services (Gemini, Claude, OpenAI, etc.)
  - Service-specific configurations
- Users can copy to `.env` and customize

### 4. Documentation

#### `README.Docker.md`
- Comprehensive Docker deployment guide
- Multiple deployment options
- Configuration instructions
- GPU support setup
- Usage examples with curl and Python
- Volume mount explanations
- Troubleshooting section
- Advanced topics (custom ports, multi-platform builds)
- Update procedures

#### `README.md` (Updated)
- Added Docker Deployment section
- Quick start examples
- Link to detailed Docker documentation

#### `examples/README_DOCKER_EXAMPLES.md`
- API usage examples
- Python, curl, and JavaScript examples
- All output format examples
- Advanced options demonstration
- Response format documentation
- Troubleshooting tips

#### `examples/test_api.py`
- Ready-to-use Python script for testing the API
- Handles file upload and conversion
- Saves output, metadata, and images
- Includes health check
- User-friendly command-line interface
- Error handling and informative messages

## Features

### Deployment Options

1. **Quick Start Script** (Recommended)
   ```bash
   ./quick-start.sh
   ```

2. **Docker Compose**
   ```bash
   docker compose up -d
   ```

3. **Pre-built Image**
   ```bash
   docker pull ghcr.io/gentle-lijie/marker-docker:latest
   docker run -d -p 8000:8000 --name marker-server ghcr.io/gentle-lijie/marker-docker:latest
   ```

4. **Local Build**
   ```bash
   docker build -t marker-pdf:latest .
   docker run -d -p 8000:8000 marker-pdf:latest
   ```

### Supported Configurations

- **CPU Mode**: Default, works everywhere
- **GPU Mode**: NVIDIA CUDA support with nvidia-docker
- **Environment Variables**: Configurable via .env file
- **Volume Mounts**: Persistent uploads and outputs
- **Health Checks**: Automatic container health monitoring
- **API Keys**: Support for all LLM services

## Architecture

```
┌─────────────────────────────────────────┐
│         GitHub Actions Workflow         │
│  (Builds and pushes to ghcr.io)        │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│    GitHub Container Registry (ghcr.io)  │
│    ghcr.io/gentle-lijie/marker-docker   │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│           User's Environment            │
│  ┌────────────────────────────────┐    │
│  │     Docker Container           │    │
│  │  ┌──────────────────────────┐  │    │
│  │  │   FastAPI Server         │  │    │
│  │  │   (Port 8000)            │  │    │
│  │  │                          │  │    │
│  │  │   Marker PDF Converter   │  │    │
│  │  └──────────────────────────┘  │    │
│  │                                 │    │
│  │  Volumes:                       │    │
│  │  - ./uploads → /app/uploads     │    │
│  │  - ./outputs → /app/outputs     │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Image Details

### Base Image
- `python:3.11-slim`: Optimized for size and security

### Installed Dependencies
- System: gcc, g++, git, libgl1-mesa-glx, libglib2.0-0, libgomp1
- Python: Poetry 1.7.1
- Project: All dependencies from pyproject.toml with [full] extras

### Image Size
- Approximately 5-6 GB (includes PyTorch and all models)

### Exposed Ports
- 8000: FastAPI server

### Environment Variables
- `PYTHONUNBUFFERED=1`: For real-time log output
- `TORCH_DEVICE=cpu`: Default to CPU (can override to cuda/mps)

### Health Check
- Interval: 30 seconds
- Timeout: 10 seconds
- Start period: 60 seconds
- Retries: 3

## Continuous Integration

The GitHub Actions workflow runs on:
- Push to `main` or `master` branch
- Push of version tags (v*.*.*)
- Pull requests (builds only, doesn't push)
- Manual trigger via workflow_dispatch

### Build Process
1. Checkout repository
2. Set up Docker Buildx
3. Log in to GitHub Container Registry
4. Extract metadata and generate tags
5. Build Docker image with layer caching
6. Push to registry (if not PR)

### Image Tags
- `latest`: Always points to the latest build from main/master
- `vX.Y.Z`: Specific version tags
- `vX.Y`: Major.minor version
- `vX`: Major version
- `main`/`master`: Branch-specific tags

## Testing

All Docker-related files have been validated:
- ✅ Dockerfile syntax verified
- ✅ docker-compose.yml validated
- ✅ GitHub Actions workflow YAML validated
- ✅ Security scan passed (0 vulnerabilities)

## Future Enhancements

Potential improvements for future versions:
1. Multi-stage builds for smaller image size
2. ARM64 support for Apple Silicon and ARM servers
3. Docker secrets integration for API keys
4. Kubernetes deployment manifests
5. Helm chart for Kubernetes
6. Docker Swarm configuration
7. Health check endpoint customization
8. Metrics and monitoring integration

## Maintenance

### Updating the Image

To update the published image:
1. Make changes to the codebase
2. Commit and push to main/master
3. GitHub Actions automatically builds and pushes new image

For versioned releases:
1. Create a git tag: `git tag v1.0.0`
2. Push the tag: `git push origin v1.0.0`
3. GitHub Actions builds and tags the image accordingly

### Local Development

To test Docker changes locally:
```bash
# Build the image
docker build -t marker-pdf:test .

# Run the container
docker run -p 8000:8000 marker-pdf:test

# Test the API
curl http://localhost:8000/
```

## Support

For issues or questions:
1. Check [README.Docker.md](README.Docker.md) for detailed documentation
2. Review [examples/README_DOCKER_EXAMPLES.md](examples/README_DOCKER_EXAMPLES.md) for usage examples
3. Check Docker container logs: `docker logs marker-server`
4. Visit API docs: http://localhost:8000/docs
5. Open an issue on GitHub

## Security Considerations

- No secrets are included in the Docker image
- API keys should be provided via environment variables
- The container runs as root (consider adding a non-root user in production)
- Health checks help ensure service availability
- Regular updates recommended to get security patches

## License

The Docker setup follows the same license as the main project:
- Code: GPL-3.0-or-later
- Models: Modified AI Pubs Open Rail-M license

---

**Ready to Deploy!** 🚀

The Marker PDF project can now be deployed with a single command, making it accessible to users who want to quickly set up a document conversion service.
