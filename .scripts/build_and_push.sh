#!/bin/bash

set -e # failOnStderr
# Début Chronomètre
SECONDS=0
ERROR_MESSAGE=""

# Docker Repository
REPOSITORY="ghcr.io/laveracloudsolutions"
# Buildx Architecture
DOCKER_PLATFORMS="--platform linux/amd64,linux/arm64"

# Build Mutli Platforms (amd64/arm64) and Push image to github
# ex: docker buildx build -t ghcr.io/laveracloudsolutions/dpage/pgadmin4:latest -t ghcr.io/laveracloudsolutions/dpage/pgadmin4:9.1 --platform linux/amd64,linux/arm64 . --push
function build_and_push_to_github()
{
  DOCKER_FOLDER=$1
  DOCKER_IMAGE_TAG=$2
  DOCKER_IMAGE_ADDITIONNAL_TAG=$3
  DOCKER_TAG="-t ${REPOSITORY}/${DOCKER_IMAGE_TAG}"
  if [ -n "$DOCKER_IMAGE_ADDITIONNAL_TAG" ]; then
    DOCKER_TAG+=" -t ${REPOSITORY}/${DOCKER_IMAGE_ADDITIONNAL_TAG}"
  fi

  pushd ${DOCKER_FOLDER}
  { # try
      docker buildx build ${DOCKER_TAG} ${DOCKER_PLATFORMS} . --push
      #docker buildx build --no-cache ${DOCKER_TAG} ${DOCKER_PLATFORMS} . --push

  } || { # catch
      echo "Build $DOCKER_FOLDER FAILED."
      ERROR_MESSAGE+="Build $DOCKER_FOLDER FAILED.\n"
  }
  popd

}

# On parse la liste des images du fichier ".scripts/images.json"
readarray -t images < <(jq -c '.images[]' .scripts/images.json)
for image in "${images[@]}"; do
    echo "image = $image"
    folder=$(echo "$image" | jq -r .folder)
    image_tag=$(echo "$image" | jq -r .image_tag)
    image_additionnal_tag=$(echo "$image" | jq -r .image_additionnal_tag)
    platforms=$(echo "$image" | jq -r .platforms)

    DOCKER_PLATFORMS="--platform ${platforms}"
    build_and_push_to_github "${folder}" "${image_tag}" "${image_additionnal_tag}"
done

## Buildx Images --platform linux/amd64,linux/arm64
#DOCKER_PLATFORMS="--platform linux/amd64,linux/arm64"
#build_and_push_to_github "pgadmin4" "dpage/pgadmin4:9.1"
#build_and_push_to_github "mailcatcher" "dockage/mailcatcher:0.9"
#build_and_push_to_github "maildev" "maildev/maildev:2.2.1"
#build_and_push_to_github "nginx" "nginx:1.27.4"
#build_and_push_to_github "node-20" "node:20-bullseye-slim"
#build_and_push_to_github "node-21" "node:21-bullseye-slim"
#build_and_push_to_github "node-22" "node:22-bullseye-slim"
#build_and_push_to_github "postgres-15" "postgres:15.12-alpine"
#build_and_push_to_github "postgres-16" "postgres:16-alpine"
#build_and_push_to_github "redis-5" "redis:5-alpine"
#build_and_push_to_github "redis-7" "redis:7.2.5-bookworm"
#build_and_push_to_github "ubuntu-20.04" "ubuntu:20.04"
#build_and_push_to_github "ubuntu-24.04" "ubuntu:24.04"
#build_and_push_to_github "wiremock-3.9" "wiremock/wiremock:3.9.2"
#build_and_push_to_github "wiremock-3.12" "wiremock/wiremock:3.12.1"
#
## Buildx Images --platform linux/amd64,linux/arm64/v8
#DOCKER_PLATFORMS="--platform linux/amd64,linux/arm64/v8"
#build_and_push_to_github "php-8.3.13" "php:8.3.13-apache-bookworm"
#build_and_push_to_github "php-runner-8.3.13" "php-runner:8.3.13-apache-bookworm" "php-runner:8.3.13-05"
#build_and_push_to_github "php-tools-8.3.13" "php-tools:8.3.13-apache-bookworm" "php-tools:8.3.13-05"
#build_and_push_to_github "php-8.4.8" "php:8.4.8-apache-bookworm"
#build_and_push_to_github "php-runner-8.4.8" "php-runner:8.4.8-apache-bookworm" "php-runner:8.4.8-01"
#build_and_push_to_github "php-tools-8.4.8" "php-tools:8.4.8-apache-bookworm" "php-tools:8.4.8-01"
#build_and_push_to_github "python-3.13" "python:3.13-slim-bookworm"
#build_and_push_to_github "python-tools-3.13" "python-tools:3.13-slim-bookworm"

# Fin Chronomètre
DURATION=$SECONDS
echo "Execution Time: $((DURATION / 60)) minutes and $((DURATION % 60)) seconds."

# Affichage des messages d'erreur (si besoin)
if [ -n "${ERROR_MESSAGE}" ]; then
  echo "Liste des builds en erreur:"
  echo -e ${ERROR_MESSAGE}
  exit 1
fi