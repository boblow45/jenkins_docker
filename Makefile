.PHONY: clean help init build
.DEFAULT_GOAL := help
SERVER_LOC = ''

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: ## remove all build artifacts 
	@echo "No clean command implemented yet"

init: build
# info at https://www.jenkins.io/doc/book/installing/docker/

# setup the network 
	docker run \
	--name jenkins-docker \
	--rm \
	--detach \
	--privileged \
	--network jenkins \
	--network-alias docker \
	--env DOCKER_TLS_CERTDIR=/certs \
	--volume jenkins-docker-certs:/certs/client \
	--volume jenkins-data:/var/jenkins_home \
	--publish 2376:2376 \
	docker:dind \
	--storage-driver overlay2

# start jenkins container
	docker run \
	--name jenkins \
	--rm \
	--detach \
	--network jenkins \
	--env DOCKER_HOST=tcp://docker:2376 \
	--env DOCKER_CERT_PATH=/certs/client \
	--env DOCKER_TLS_VERIFY=1 \
	--publish 8080:8080 \
	--publish 50000:50000 \
	--volume jenkins-data:/var/jenkins_home \
	--volume jenkins-docker-certs:/certs/client:ro \
	jenkins-docker:1.1 

build: ## Build jenkins docker image with all its requirements 
	docker build -t  jenkins-docker:1.1 .