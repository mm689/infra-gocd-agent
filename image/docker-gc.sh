#!/bin/bash

docker run --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc:ro -e MINIMUM_IMAGES_TO_SAVE=3 -e FORCE_IMAGE_REMOVAL=1 spotify/docker-gc

docker volume prune -f
docker image prune -af
