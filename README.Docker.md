# Docker Deployment Guide

This guide explains how to deploy the Marker PDF converter using Docker for one-click deployment.

## Quick Start with Docker

### Option 1: Using Docker Compose (Recommended)

1. Clone the repository:
```bash
git clone https://github.com/Gentle-Lijie/marker-docker.git
cd marker-docker
```

2. Start the service:
```bash
docker-compose up -d
```

3. Access the API at `http://localhost:8000`
   - API docs: `http://localhost:8000/docs`
   - Health check: `http://localhost:8000/`

4. Stop the service:
```bash
docker-compose down
```

### Option 2: Using Pre-built Image from GitHub Container Registry

Pull and run the pre-built image:

```bash
docker pull ghcr.io/gentle-lijie/marker-docker:latest
docker run -d -p 8000:8000 --name marker-server ghcr.io/gentle-lijie/marker-docker:latest
```

### Option 3: Building from Source

Build the Docker image locally:

```bash
docker build -t marker-pdf:latest .
docker run -d -p 8000:8000 --name marker-server marker-pdf:latest
```

## Configuration

### Environment Variables

You can configure the service using environment variables:

- `TORCH_DEVICE`: Set to `cpu`, `cuda`, or `mps` (default: `cpu`)
- `GOOGLE_API_KEY`: For Gemini LLM support (optional)
- `ANTHROPIC_API_KEY`: For Claude LLM support (optional)

Example with environment variables:

```bash
docker run -d \
  -p 8000:8000 \
  -e TORCH_DEVICE=cpu \
  -e GOOGLE_API_KEY=your_api_key \
  --name marker-server \
  ghcr.io/gentle-lijie/marker-docker:latest
```

Or using docker-compose, create a `.env` file:

```env
TORCH_DEVICE=cpu
GOOGLE_API_KEY=your_api_key_here
ANTHROPIC_API_KEY=your_api_key_here
```

### GPU Support

For GPU support with NVIDIA GPUs:

1. Install [NVIDIA Docker runtime](https://github.com/NVIDIA/nvidia-docker)

2. Modify `docker-compose.yml` to uncomment the GPU section:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

3. Set environment variable:
```bash
TORCH_DEVICE=cuda docker-compose up -d
```

Or with Docker command:

```bash
docker run -d \
  -p 8000:8000 \
  -e TORCH_DEVICE=cuda \
  --gpus all \
  --name marker-server \
  ghcr.io/gentle-lijie/marker-docker:latest
```

## Usage

### Upload and Convert a PDF

Using curl:

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@/path/to/your/document.pdf" \
  -F "output_format=markdown"
```

Using Python:

```python
import requests

with open("document.pdf", "rb") as f:
    files = {"file": f}
    data = {
        "output_format": "markdown",
        "force_ocr": False
    }
    response = requests.post("http://localhost:8000/marker/upload", files=files, data=data)
    result = response.json()
    print(result["output"])
```

### API Endpoints

- `GET /`: Home page with links
- `GET /docs`: Interactive API documentation (Swagger UI)
- `POST /marker`: Convert PDF from filepath (requires file on server)
- `POST /marker/upload`: Upload and convert PDF

### Convert Parameters

- `output_format`: `markdown`, `json`, `html`, or `chunks` (default: `markdown`)
- `page_range`: Specific pages to convert, e.g., `"0,5-10,20"`
- `force_ocr`: Force OCR on all pages (default: `false`)
- `paginate_output`: Add page separators to output (default: `false`)

## Volume Mounts

The Docker setup includes two volume mounts:

- `./uploads`: Temporary storage for uploaded files
- `./outputs`: Storage for conversion outputs

These directories are automatically created and can be customized in `docker-compose.yml`.

## Troubleshooting

### Container fails to start

Check logs:
```bash
docker logs marker-server
```

Or with docker-compose:
```bash
docker-compose logs -f
```

### Out of Memory

If you experience memory issues:

1. Increase Docker memory limit in Docker Desktop settings
2. Use smaller batch sizes
3. Convert fewer pages at once using `page_range`

### Permission Issues

If you encounter permission issues with volumes:

```bash
sudo chown -R $USER:$USER uploads outputs
```

## Advanced Configuration

### Custom Port

To use a different port:

```bash
docker run -d -p 8080:8000 --name marker-server ghcr.io/gentle-lijie/marker-docker:latest
```

Or in `docker-compose.yml`, change:
```yaml
ports:
  - "8080:8000"
```

### Building Multi-platform Images

To build for multiple architectures:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t marker-pdf:latest .
```

## Updating

### Using Docker Compose

```bash
docker-compose pull
docker-compose up -d
```

### Using Docker Command

```bash
docker pull ghcr.io/gentle-lijie/marker-docker:latest
docker stop marker-server
docker rm marker-server
docker run -d -p 8000:8000 --name marker-server ghcr.io/gentle-lijie/marker-docker:latest
```

## CI/CD and Automated Builds

This repository includes a GitHub Actions workflow that automatically:

1. Builds the Docker image on push to main/master branch
2. Builds on version tags (e.g., `v1.0.0`)
3. Pushes the image to GitHub Container Registry (ghcr.io)
4. Tags with version numbers and `latest`

The workflow is defined in `.github/workflows/docker-publish.yml`.

## Contributing

When contributing Docker-related changes, please:

1. Test the Dockerfile builds successfully
2. Verify the container runs and passes health checks
3. Update this documentation if you add new features
4. Test with both CPU and GPU configurations if applicable
