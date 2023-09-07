# Build Windup UI container from sources

Read [https://github.com/jboss-dockerfiles/wildfly](https://github.com/jboss-dockerfiles/wildfly)
The WindUp Docker image is built using jKube, see the [POM file](https://github.com/windup/windup-openshift/blob/master/web/pom.xml#L15).

There is a Dockerfile in the WindUp Distribution at XXX

## Prerequisites

The following prerequisites are required to use this application. Please ensure that you have them all installed locally.

- [Java 11](https://learn.microsoft.com/en-us/java/openjdk/install) - Windup does not yet support Java 17
- [Docker](https://docs.docker.com/get-docker/)


```sh
export AZURE_AZURE_LOCATION=westeurope
export RESOURCE_GROUP_NAME=rg-aca-windup

az group create --name $RESOURCE_GROUP_NAME --AZURE_LOCATION $AZURE_LOCATION
docker login

#git clone https://github.com/windup/windup-openshift
#sudo apt-get install podman --yes
#cd windup-openshift
#mvn clean install -Ddocker.name.windup.web=<your_quay_id>/windup-web-openshift -Ddocker.name.windup.web.executor=<your_quay_id>/windup-web-openshift-messaging-executor
# mvn clean package -DskipTests

```
### WSL pre-req

This is optional, only if you do prefer to use WSL instead of Codespaces.


```sh
az login
azd login
```
If the above login CLI command fails on WSL-Ubuntu 22.04 with error xdg-open: no method available for opening 'https://microsoft.com'
See [https://github.com/microsoft/WSL/issues/8892](https://github.com/microsoft/WSL/issues/8892)
Run the snippet below
```sh
sudo apt-get update
sudo apt install xdg-utils --yes
sudo apt install wslu --yes
xdg-settings set default-web-browser edge.desktop
# BROWSER=/mnt/c/Firefox/firefox.exe
# BROWSER="/mnt/c/Program\ Files/Google/Chrome/Application/chrome.exe"
# BROWSER=/mnt/c/Windows/SystemApps/Microsoft.MicrosoftEdge_8wekyb3d8bbwe
```

Install Docker
```sh
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Download and add Docker's official public PGP key.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Verify the fingerprint.
sudo apt-key fingerprint 0EBFCD88

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io --yes
apt-cache madison docker-ce

sudo apt update
sudo apt upgrade
# sudo apt install docker.io
sudo docker --version

# sudo cgroupfs-mount
# sudo usermod -aG docker $USER

# https://askubuntu.com/questions/1380051/docker-unrecognized-service-when-installing-cuda
service --status-all
sudo service docker start
sudo service docker status
```

```sh
UNIQUEID=$(openssl rand -hex 3)

export AZURE_ENV_NAME=windup42
export AZURE_AZURE_LOCATION=westeurope
export RESOURCE_GROUP_NAME=rg-aca-windup
# export AZURE_STORAGE_NAME="sta""${UNIQUEID,,}"
# unset AZURE_STORAGE_NAME
export AZURE_FILE_SHARE_SERVICE_NAME=windup
export AZURE_PRINCIPAL_ID=

```

## Build

The Docker file is located at [./src/Dockerfile](./src/Dockerfile)

```sh
WINDUP_VERSION="6.2.0-SNAPSHOT"
BUILD_ID="20230330.071913-130-with-authentication"

# https://repo1.maven.org/maven2/org/jboss/windup/web/windup-web-distribution/6.1.7.Final/windup-web-distribution-6.1.7.Final-with-authentication.zip

#wget https://repo1.maven.org/maven2/org/jboss/windup/windup-cli/${WINDUP_VERSION}.Final/windup-cli-${WINDUP_VERSION}.Final-offline.zip
#gunzip windup-cli-${WINDUP_VERSION}.Final-offline.zip

git clone https://github.com/windup/windup

DISTRIBUTION_DIR=dist
mkdir $DISTRIBUTION_DIR

wget https://repo1.maven.org/maven2/org/jboss/windup/web/windup-web-distribution/${WINDUP_VERSION}.Final/windup-web-distribution-${WINDUP_VERSION}.Final-with-authentication.zip -O $DISTRIBUTION_DIR

cd $DISTRIBUTION_DIR
unzip windup-web-distribution-${WINDUP_VERSION}.Final-with-authentication.zip

DOCKER_BUILDKIT=0 DOCKER_DEFAULT_PLATFORM=linux/amd64 docker build --build-arg --no-cache -t "windup" -f "./src/Dockerfile" .
docker tag windup acrwindupaca.azurecr.io/windup/windup
docker push acrwindupaca.azurecr.io/windup/windup
docker pull acrwindupaca.azurecr.io/windup/windup

docker image ls | grep -i windup
docker image prune"

ip addr show eth0 | grep inet
sudo apt install net-tools
ifconfig -a | grep  -i inet
host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address"

JBOSS_CONTAINER_HOST=$(hostname -I)
JBOSS_CONTAINER_HOST=$(curl icanhazip.com)
JBOSS_CONTAINER_HOST=$(dig +short myip.opendns.com @resolver1.opendns.com)
JBOSS_CONTAINER_HOST=$(curl whatismyip.akamai.com)

# ./bin/add-user.sh --user adm-jboss --password adm-jboss --enable --display-secret
# Check : standalone/configuration/mgmt-users.properties, standalone/configuration/mgmt-groups.properties
# domain/configuration/mgmt-users.properties, domain/configuration/mgmt-groups.properties

```

Note: if you want to run the Windup CLIn you ucan use the latest tag check at : [https://quay.io/repository/windupeng/windup-cli-openshift?tab=tags](https://quay.io/repository/windupeng/windup-cli-openshift?tab=tags), it will require [Azure Files which is supported by ACA](https://learn.microsoft.com/en-us/azure/container-apps/storage-mounts?pivots=azure-cli#azure-files)


FYI the UI code is located at [https://github.com/windup/windup-web/blob/master/ui-pf4/src/main/webapp/src](https://github.com/windup/windup-web/blob/master/ui-pf4/src/main/webapp/src)

## Run


```sh

docker run --env JBOSS_CONTAINER_HOST=$JBOSS_CONTAINER_HOST -p 8080:8080 -p 9990:9990 -p 8042:8042 -p 9993:9993 -p 8443:8443 quay.io/windupeng/windup-web-openshift

docker run --env JBOSS_CONTAINER_HOST=$JBOSS_CONTAINER_HOST -p 8080:8080 -p 9990:9990 -p 8042:8042 -p 9993:9993 -p 8443:8443 windup:latest

```
