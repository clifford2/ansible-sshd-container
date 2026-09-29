# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

IMG_VERSION := $(shell cat .version)
SSH_PUBKEY := $(shell cat ~/.ssh/id_ed25519.pub)
SSH_PORT := 2943
LOCAL_IMAGE_NAME := localhost/aap-demo-sshd:$(IMG_VERSION)
PUBLISHED_IMAGE_NAME := docker.io/cliffordw/aap-demo-sshd:$(IMG_VERSION)
CONTAINER_NAME := "aap-demo-sshd"
TRIVY_IMAGE := "docker.io/aquasec/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969"

.PHONY: help
help:
	@echo "No default target"
	@echo "Image: $(LOCAL_IMAGE_NAME)"

.PHONY: build
build:
	podman build -t $(LOCAL_IMAGE_NAME) .

.PHONY: build-centos
build-centos:
	podman build -t $(LOCAL_IMAGE_NAME)-centos centos

.PHONY: run
run:
	podman run -d --rm -it --replace --name $(CONTAINER_NAME) --hostname $(CONTAINER_NAME) -e TZ=Africa/Johannesburg -e SSH_PUBLIC_KEY="$(SSH_PUBKEY)" -e SUDO_ACCESS=true -e SSH_LISTEN_PORT=$(SSH_PORT) --network=host $(LOCAL_IMAGE_NAME)
	podman ps | grep -w $(CONTAINER_NAME)

.PHONY: stop
stop:
	podman stop $(CONTAINER_NAME)

.PHONY: shell
shell:
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $(SSH_PORT) ansible@127.0.0.1

.PHONY: uname
uname:
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $(SSH_PORT) ansible@127.0.0.1 sh -c 'uname -a; uptime; ps -ef'

.PHONY: .sleep
.sleep:
	sleep 2

.PHONY: test
test: run .sleep uname stop

.PHONY: push-to-docker
push-to-docker:
	podman tag $(LOCAL_IMAGE_NAME) $(PUBLISHED_IMAGE_NAME)
	podman push $(PUBLISHED_IMAGE_NAME)

.PHONY: trivy
trivy:
	podman run --rm -v /run/user/$(shell id -u)/podman/podman.sock:/var/run/podman/podman.sock:z -v ~/.cache/trivy:/root/.cache/:Z $(TRIVY_IMAGE) image $(LOCAL_IMAGE_NAME) --exit-code 1 --no-progress --severity HIGH,CRITICAL --podman-host /var/run/podman/podman.sock
