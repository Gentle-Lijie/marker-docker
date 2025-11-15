FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    poppler-utils \
    tesseract-ocr \
    libpango-1.0-0 \
    libharfbuzz0b \
    libpangoft2-1.0-0 \
    libgdk-pixbuf-xlib-2.0-0 \
    libcairo2 \
    libffi-dev \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgl1 \
    ca-certificates \
    curl \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*


# Copy source (after copying pyproject to allow any package metadata to be read during install)
COPY pyproject.toml poetry.lock* README.md /app/
COPY . /app

RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir .
RUN pip install --no-cache-dir fastapi uvicorn[standard] python-multipart


RUN mkdir -p /app/uploads

EXPOSE 8001

CMD ["uvicorn", "marker.scripts.server:app", "--host", "0.0.0.0", "--port", "8001"]