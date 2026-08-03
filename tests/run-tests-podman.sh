#!/usr/bin/env bash
# Run the package test suite locally in the same container image used by CI,
# via podman (e.g. on macOS with Podman Desktop / podman machine).
#
# Usage:
#   ./tests/run-tests-podman.sh
#
# Mirrors .github/workflows/tests.yml, but runs with podman instead of docker.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v podman >/dev/null 2>&1; then
  echo "Error: podman is not installed or not on PATH. Install it with 'brew install podman'." >&2
  exit 1
fi

if ! podman info >/dev/null 2>&1; then
  echo "Podman machine is not running. Starting it..." >&2
  podman machine start
fi

IMAGE=$(jq -r '.base_image' .codeocean/environment.json)
IMAGE=${IMAGE//codeocean/nciccbr}
echo "Using image: $IMAGE"

podman run --rm \
  -v "$REPO_ROOT":/workspace:Z \
  -w /workspace \
  "$IMAGE" \
  Rscript tests/testthat.R
