#!/bin/bash
set -e

# Function to print messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting Marker PDF Server..."
log "TORCH_DEVICE: ${TORCH_DEVICE:-cpu}"

# Wait for any initialization if needed
sleep 2

# Execute the main command
exec "$@"
