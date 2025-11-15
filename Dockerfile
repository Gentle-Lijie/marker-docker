# Use Python 3.11 slim image for smaller size
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    git \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install --no-cache-dir poetry==1.7.1

# Copy only dependency files first for better caching
COPY pyproject.toml poetry.lock ./

# Configure poetry to not create virtual environment and install dependencies
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root --extras "full"

# Copy the rest of the application
COPY . .

# Install the package itself
RUN poetry install --no-interaction --no-ansi --only-root

# Create directories for uploads and outputs
RUN mkdir -p /app/uploads /app/outputs

# Setup entrypoint script
RUN cp docker-entrypoint.sh /usr/local/bin/ && chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port for FastAPI server
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV TORCH_DEVICE=cpu

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/', timeout=5)" || exit 1

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command: run the marker server
CMD ["marker_server", "--host", "0.0.0.0", "--port", "8000"]
