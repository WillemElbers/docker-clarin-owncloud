DOCKER_IMAGE_NAME=docker.clarin.eu/owncloud
DOCKER_IMAGE_VERSION=1.0.1

all: build

build:
	@echo "Building docker image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}"
	@docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION} . >> docker_build.log 2>&1

push:
	@docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}


