#!/usr/bin/env bash
set -Eeuo pipefail

# Runs build.odin using Odin.
# If the first argument is "docker", runs build.odin using Docker.
# For further usage, see build.odin.

SCRIPT_DIR="$(cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)"
cd -- "$SCRIPT_DIR"

if [[ "${1:-}" == "docker" ]]; then
    shift

    if ! command -v docker >/dev/null 2>&1; then
        echo "[ERROR] Docker is not installed or not available in PATH." >&2
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "[ERROR] Docker is not running." >&2
        echo "Start Docker Desktop or the Docker daemon, then try again." >&2
        exit 1
    fi

    # Normalize the project directory name for use as a Docker image name.
    project_name="$(basename -- "$SCRIPT_DIR")"
    project_name="$(printf '%s' "$project_name" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9._-]+/-/g; s/^[._-]+//; s/[._-]+$//')"

    [[ -n "$project_name" ]] || project_name="odin-project"
    image="${project_name}-build:local"

    # Convert the host path for Docker Desktop when running under Git Bash.
    if command -v cygpath >/dev/null 2>&1; then
        project_dir="$(cygpath -m "$SCRIPT_DIR")"
    else
        project_dir="$SCRIPT_DIR"
    fi

    printf '\033[36mBuilding using Docker image: %s\033[0m\n' "$image"
    MSYS_NO_PATHCONV=1 DOCKER_CLI_HINTS=false docker build \
        -f build.Dockerfile \
        -t "$image" \
        -q \
        .

    MSYS_NO_PATHCONV=1 DOCKER_CLI_HINTS=false exec docker run --rm \
        --mount "type=bind,source=$project_dir,target=/workspace" \
        -w /workspace \
        "$image" \
        odin run build.odin -file -- "$@"
fi

if ! command -v odin >/dev/null 2>&1; then
    echo "[ERROR] Odin is not installed or not available in PATH." >&2
    exit 1
fi

exec odin run build.odin -file -- "$@"
