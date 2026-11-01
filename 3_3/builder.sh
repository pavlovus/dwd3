#!/bin/sh

if [ "$#" -ne 2 ]; then
  echo "Usage: ./builder.sh <github-repo> <docker-image>"
  exit 1
fi

# Fail on any command error and on use of unset variables.
set -eu

github_repo="$1"
docker_image="$2"

# Clone into a throwaway directory so nothing is left behind, even on failure.
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Cloning https://github.com/${github_repo} ..."
git clone --depth 1 "https://github.com/${github_repo}.git" "$workdir"

if [ ! -f "$workdir/Dockerfile" ]; then
  echo "Error: no Dockerfile found in the root of ${github_repo}" >&2
  exit 1
fi

echo "Building image ${docker_image} ..."
docker build -t "$docker_image" "$workdir"

echo "Pushing ${docker_image} to Docker Hub ..."
docker push "$docker_image"

echo "Done."