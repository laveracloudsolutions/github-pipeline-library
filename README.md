# Github Pipeline Library

Projet permettant de mutualiser les pipelines / fichiers / scripts nécessaires à la mise à jour des images Docker définis dans les différents repositories de type "Dockerfile | Docker Images"

[[_TOC_]]

## Principe de Fonctionnement

### Images Tags (images.json)

Chaque projet contient un ou plusieurs Dockerfile à préparer, la liste des images à préparer est définie dans le fichier [.scripts/images.json](.scripts/images.json)

Exemple:

```bash
{
  "images": [
    {
      # Répertoire où chercher un fichier "Dockerfile"
      "folder": "php-runner-8.3.13", 
      # Nom du Tag Docker à appliquer lors du build
      "image_tag": "php-runner-8.3.13:lastest",
      # Tag Docker additionnel (une même image peut avoir plus nom/tag)
      "image_additionnal_tag": "php-runner-8.3.13-01",
      # Type de plateforme cible / Build de l'image Docker pour être optimisé pour plusieurs type de plateforme (unix, macos, etc)
      "platforms": "amd/arm"
    },
    ...
  ]
}
```

### Build And Push (multiplateforme)

Le script [.scripts/build_and_push.sh](.scripts/build_and_push.sh) permet 
* de charger un fichier ".scripts/images.json"
* de le parcourir la liste des images à préparer
* de builder / tagguer / pusher dang Github (ghcr.io) les images pour chaque plateforme souhaitée

IMPORTANT: 
* La préparation d'une image multiplateforme doit se faire en une seule étape (voir exemple ci-dessous)
* Il n'est pas possible de créer une image avec un tag spécifique pour une plateforme puis, dans un second temps de pousser un même tag docker pour une plateforme différente. Le deuxième push va écraser le premier.

Pour builder une image compatible avec plusiueurs plateformes

```bash
# Nom du tag
DOCKER_TAG="workshop:latest"

# Buildx Architecture
DOCKER_PLATFORMS="--platform linux/amd64,linux/arm64"

# Build multi plateforme
docker buildx build ${DOCKER_TAG} ${DOCKER_PLATFORMS} . --push
```

Ce script est mutualisé / utilisé par l'ensemble des projets Github Petroineos de type "Dockerfile | Docker images".

Dans chaque projet, le script ".scripts/build_and_push.sh" est chargé / exécuté de la manière suivante

```bash
# Récupération du script depuis la branche "main" du projet "github-pipeline-library"
wget https://raw.githubusercontent.com/laveracloudsolutions/github-pipeline-library/refs/heads/main/.scripts/build_and_push.sh -O /tmp/build_and_push.sh

# Execution du Script
chmod +x /tmp/build_and_push.sh
/tmp/build_and_push.sh
```

### Github Action

Le pipeline Github Actions [.github/workflows/build.yml](.github/workflows/build.yml) contient:
* les directives concernant le "runner"
* le chargement de step qui vont permettre de build des images de type "arm" ET "amd"
* l'execution du script principal "build_and_push.sh"

Ce pipeline "commun" est chargé par chaque pipeline projet de la manière suivante

```yaml
jobs:
  github-pipeline-library:
    uses: laveracloudsolutions/github-pipeline-library/.github/workflows/build.yml@main
    with:
      config-path: .github/images.json
    secrets: inherit
```

## Docker Image | GHCR.IO | Github Action
___
> [Voir Wiki](https://dev.azure.com/petrolavera/ArchitectureApplicative/_wiki/wikis/Architecture%20applicative/340/Images-Docker-(-GitHub))
___