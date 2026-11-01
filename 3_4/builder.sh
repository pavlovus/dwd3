#!/bin/sh

if [ "$#" -ne 2 ]; then
  echo "Usage: ./builder.sh <github-repo> <docker-image>"
  exit 1
fi

# Fail on any command error and on use of unset variables.
set -eu

github_repo="$1"
docker_image="$2"

# ${VAR:-} keeps `set -u` from aborting with a cryptic message,
# so we can print a helpful one instead.
if [ -z "${DOCKER_USER:-}" ] || [ -z "${DOCKER_PWD:-}" ]; then
  echo "Error: DOCKER_USER and DOCKER_PWD environment variables must be set" >&2
  exit 1
fi

# Clone into a throwaway directory so nothing is left behind, even on failure.
workdir="$(mktemp -d)"
cleanup() {
  docker logout >/dev/null 2>&1 || true
  rm -rf "$workdir"
}
trap cleanup EXIT

echo "Cloning https://github.com/${github_repo} ..."
git clone --depth 1 "https://github.com/${github_repo}.git" "$workdir"

if [ ! -f "$workdir/Dockerfile" ]; then
  echo "Error: no Dockerfile found in the root of ${github_repo}" >&2
  exit 1
fi

echo "Building image ${docker_image} ..."
docker build -t "$docker_image" "$workdir"

echo "Logging in to Docker Hub as ${DOCKER_USER} ..."
# --password-stdin keeps the password out of the process list.
printf '%s' "$DOCKER_PWD" | docker login --username "$DOCKER_USER" --password-stdin

echo "Pushing ${docker_image} to Docker Hub ..."
docker push "$docker_image"

echo "Done."