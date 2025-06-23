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

# Fin Chronomètre
DURATION=$SECONDS
echo "Execution Time: $((DURATION / 60)) minutes and $((DURATION % 60)) seconds."

# Affichage des messages d'erreur (si besoin)
if [ -n "${ERROR_MESSAGE}" ]; then
  echo "Liste des builds en erreur:"
  echo -e ${ERROR_MESSAGE}
  exit 1
fi