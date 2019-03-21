CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := vault-operator
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init: 
	helm init --client-only

setup: init
	helm repo add jenkins-x http://chartmuseum.jenkins-x.io 	

build: clean setup
	helm dependency build ${NAME}
	helm lint ${NAME}

install: clean build
	helm upgrade ${NAME} ${NAME} --install

upgrade: clean build
	helm upgrade ${NAME} ${NAME} --install

delete:
	helm delete --purge ${NAME} ${NAME}

clean:
	rm -rf ${NAME}/charts
	rm -rf ${NAME}/${NAME}*.tgz
	rm -rf ${NAME}/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" ${NAME}/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" ${NAME}/Chart.yaml
else
	exit -1
endif
	helm package 
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
