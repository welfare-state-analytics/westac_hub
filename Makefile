# Copyright (c) Humlab Development Team.
# Distributed under the terms of the Modified BSD License.

include .env

.DEFAULT_GOAL=build

build: check-files network host-volume lab-image hub-image
	@echo "Build done"

rebuild: down clear-user-volumes build up
	@echo "Rebuild done"
	@exit 0

network:
	@docker network inspect $(HUB_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(HUB_NETWORK_NAME)

host-volume:
	@docker volume inspect $(HUB_HOST_VOLUME_NAME) >/dev/null 2>&1 || docker volume create --name $(HUB_HOST_VOLUME_NAME)
	@echo "info: remember to clear host volume if jupyterhub_config.py has been changed!"
	# docker volume rm $(HUB_HOST_VOLUME_NAME)

secrets/.env.oauth2:
	@echo "File .env.oauth2 file is missing (GitHub parameters)"
	@exit 1

userlist:
	@echo "Add usernames, one per line, to ./userlist, such as:"
	@echo "    zoe admin"
	@echo "    wash"
	@exit 1

check-files: config/userlist secrets/.env.oauth2

hub-image:
	@docker-compose build
	@docker tag $(HUB_IMAGE_NAME):latest $(HUB_IMAGE_NAME):$(PYPI_PACKAGE_VERSION)

lab-image:
	@echo "Building lab image"
	docker build \
		--build-arg PYPI_PACKAGE=$(PYPI_PACKAGE) \
		--build-arg PYPI_PACKAGE_VERSION=$(PYPI_PACKAGE_VERSION) \
		--build-arg GITHUB_ORG=$(GITHUB_ORG) \
		--build-arg GITHUB_REPOSITORY=$(GITHUB_REPOSITORY) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		--build-arg LAB_PORT=$(LAB_PORT) \
		-t $(LAB_IMAGE_NAME):latest \
		-t $(LAB_IMAGE_NAME):$(PYPI_PACKAGE_VERSION) \
		-f $(LAB_IMAGE_NAME)/Dockerfile $(LAB_IMAGE_NAME)

run-lab-image:
	docker run --rm -p ${LAB_PORT}:${LAB_PORT} --mount "type=bind,source=/data,target=/data" $(LAB_IMAGE_NAME):latest

bash-hub:
	@docker exec -it -t $(HUB_CONTAINER_NAME) /bin/bash

bash-lab:
	@docker exec -it -t `docker ps -f "ancestor=$(LAB_IMAGE_NAME)" -q --all | head -1` /bin/bash

USER_VOLUMES=$(shell docker volume ls -q | grep -E 'jupyterhub-$(PROJECT_NAME)')
USER_VOLUMES_BACKUP_NAME="jupyterhub-$(PROJECT_NAME)-user-volumes-"`date '+%Y%m%d-%H%M'`.tar.gz

.ONESHELL:
clear-user-volumes: backup-user-volumes
	@if [ "$(USER_VOLUMES)" != "" ]; then \
		echo "Removing user volumes: $(USER_VOLUMES)" ; \
		docker volume rm $(USER_VOLUMES) ; \
	fi

.ONESHELL:
backup-user-volumes:
	@echo "Backing up to $(USER_VOLUMES_BACKUP_NAME)"
	@find /var/lib/docker/volumes -maxdepth 1 -mindepth 1 -name "*$(PROJECT_NAME)*" -not -type l -print | \
		tar -czvf $(USER_VOLUMES_BACKUP_NAME) --files-from=- >/dev/null 2>&1

clean: down
	-docker rm `docker ps -f "ancestor=$(LAB_IMAGE_NAME)" -q --all` >/dev/null 2>&1
	-docker rm `docker ps -f "ancestor=westac_jupyterhub" -q --all` >/dev/null 2>&1
	@docker volume rm `docker volume ls -q`

down:
	-docker-compose down

up:
	@docker-compose up -d

follow-hub:
	@docker logs $(LAB_IMAGE_NAME) --follow

follow-lab:
	@docker logs `docker ps -f "ancestor=$(LAB_IMAGE_NAME)" -q --all | head -1` --follow

restart: down up follow

nuke:
	-docker stop `docker ps --all -q`
	-docker rm -fv `docker ps --all -q`
	-docker images -q --filter "dangling=true" | xargs docker rmi

.PHONY: bash-hub bash-lab follow-hub follow-lab
.PHONY: clear-user-volumes clean
.PHONY: down up build restart network userlist host-volume
.PHONY: lab-image hub-image
.PHONY: nuke



