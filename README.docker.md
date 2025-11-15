# Docker Usage

This document explains how to build and run a Docker image for this project.

Requirements:
- Docker 20+ and docker-compose (optional)

Build using Docker:

```powershell
docker build -t marker:latest .
```

Run the container (exposes port 8001):

```powershell
docker run --rm -it -p 8001:8001 -v ${PWD}/uploads:/app/uploads marker:latest
```

Or using docker-compose:

```powershell
docker compose up --build
```

Notes:


.0
.
- By default the server runs at http://localhost:8001. Visit `http://localhost:8001/docs` to try the API.
- The container sets `TORCH_DEVICE=cpu` by default. To use GPU, start from an appropriate CUDA image and set TORCH_DEVICE accordingly (e.g., `TORCH_DEVICE=cuda`).
- This Dockerfile installs `fastapi` and `uvicorn` (the server) even though they're in the project dev dependencies so the server runs inside the image.
- The image installs additional OS packages such as `tesseract` and `poppler-utils` needed by the PDF tools.