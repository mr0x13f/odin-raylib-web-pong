#!/usr/bin/env bash
set -e

# Runs build.odin using Odin
# If the first argument is "docker", will run build.odin using Docker
# For further usage, see build.odin

cd -- "$(dirname -- "$(realpath -- "$0")")"

if [[ "${1:-}" == "docker" ]]; then
    shift

    if ! command -v docker >/dev/null 2>&1; then
        echo "Error: Docker is not installed or not available in PATH." >&2
        echo "Install Docker to use: build.sh docker [arguments...]" >&2
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running or you don't have permission to access it." >&2
        echo "Start Docker Desktop or the Docker daemon, then try again." >&2
        exit 1
    fi

    image="odin-build:local"

    echo "Building Docker image..."
    docker build -f build.Dockerfile -t "$image" .

    echo "Running build in Docker..."
    exec docker run --rm \
        -v "$PWD:/workspace" \
        -w /workspace \
        "$image" \
        odin run build.odin -file -- "$@"
fi

exec odin run build.odin -file -- "$@"
