# Copyright (c) Humlab Development Team.
# Distributed under the terms of the Modified BSD License.

include .env

USER_VOLUMES=$(shell docker volume ls -q | grep -E 'jupyterhub-westac')

.DEFAULT_GOAL=build

build: check-files network volumes lab_image
	docker-compose build

rebuild: down clear_volumes build up
	@echo "Rebuild done"
	@exit 0

network:
	@docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)

volumes:
	@docker volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DATA_VOLUME_HOST)

secrets/.env.oauth2:
	@echo "File .env.oauth2 file is missing (GitHub parameters)"
	@exit 1

userlist:
	@echo "Add usernames, one per line, to ./userlist, such as:"
	@echo "    zoe admin"
	@echo "    wash"
	@exit 1

check-files: config/userlist secrets/.env.oauth2

lab_image:
	@echo "Building lab image"
	docker build \
		--build-arg PYPI_PACKAGE=$(PYPI_PACKAGE) \
		--build-arg PYPI_PACKAGE_VERSION=$(PYPI_PACKAGE_VERSION) \
		--build-arg GITHUB_ORG=$(GITHUB_ORG) \
		--build-arg GITHUB_REPOSITORY=$(GITHUB_REPOSITORY) \
		-t $(LOCAL_NOTEBOOK_IMAGE):latest \
		-t $(LOCAL_NOTEBOOK_IMAGE):$(PYPI_PACKAGE_VERSION) \
		-f $(LOCAL_NOTEBOOK_IMAGE)/Dockerfile $(LOCAL_NOTEBOOK_IMAGE)

bash:
	@docker exec -it -t $(HUB_CONTAINER_NAME) /bin/bash

bash_lab:
	@docker exec -it -t `docker ps -f "ancestor=$(LOCAL_NOTEBOOK_IMAGE)" -q --all | head -1` /bin/bash



.ONESHELL:
clear_volumes:
	@if [ "$(USER_VOLUMES)" != "" ]; then \
		echo "Removing user volumes: $(USER_VOLUMES)" ; \
		docker volume rm $(USER_VOLUMES) ; \
	fi

clean: down
	-docker rm `docker ps -f "ancestor=$(LOCAL_NOTEBOOK_IMAGE)" -q --all` >/dev/null 2>&1
	-docker rm `docker ps -f "ancestor=westac_jupyterhub" -q --all` >/dev/null 2>&1
	@docker volume rm `docker volume ls -q`

down:
	-docker-compose down

up:
	@docker-compose up -d

follow:
	@docker logs $(LOCAL_NOTEBOOK_IMAGE) --follow

follow_lab:
	@docker logs `docker ps -f "ancestor=$(LOCAL_NOTEBOOK_IMAGE)" -q --all | head -1` --follow

restart: down up follow

nuke:
	-docker stop `docker ps --all -q`
	-docker rm -fv `docker ps --all -q`
	-docker images -q --filter "dangling=true" | xargs docker rmi


.PHONY: bash clear_volumes clean down up follow build restart pull nuke network userlist
