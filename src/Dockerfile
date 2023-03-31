# DOCKER_BUILDKIT=0 DOCKER_DEFAULT_PLATFORM=linux/amd64 docker build --build-arg --no-cache -t "windup" -f "./src/Dockerfile" .
# docker tag windup acrwindupaca.azurecr.io/windup/windup
# docker push acrwindupaca.azurecr.io/windup/windup
# docker pull acrwindupaca.azurecr.io/windup/windup
# docker image ls | grep -i windup
# docker image prune"

# ip addr show eth0 | grep inet

# sudo apt install net-tools
# ifconfig -a | grep  -i inet

# host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address"
# JBOSS_CONTAINER_HOST=$(hostname -I)
# JBOSS_CONTAINER_HOST=$(curl icanhazip.com)
# JBOSS_CONTAINER_HOST=$(dig +short myip.opendns.com @resolver1.opendns.com)
# JBOSS_CONTAINER_HOST=$(curl whatismyip.akamai.com)

# ./bin/add-user.sh --user adm-jboss --password adm-jboss --enable --display-secret
# Check : standalone/configuration/mgmt-users.properties, standalone/configuration/mgmt-groups.properties
# domain/configuration/mgmt-users.properties, domain/configuration/mgmt-groups.properties

# docker run --env JBOSS_CONTAINER_HOST=$JBOSS_CONTAINER_HOST -p 8080:8080 -p 9990:9990 -p 8042:8042 -p 9993:9993 -p 8443:8443 quay.io/windupeng/windup-web-openshift
# docker run --env JBOSS_CONTAINER_HOST=$JBOSS_CONTAINER_HOST -p 8080:8080 -p 9990:9990 -p 8042:8042 -p 9993:9993 -p 8443:8443 windup:latest
# docker container ls
# docker ps
# docker exec -it <container-id> /bin/sh

# https://docs.microsoft.com/en-us/java/openjdk/containers

FROM mcr.microsoft.com/openjdk/jdk:11-mariner
LABEL Maintainer="pinpin <noname@microsoft.com>"
LABEL Description="Windup built from MS OpenJDK 11-Mariner"
RUN mkdir /tmp/app
WORKDIR /tmp/app
# "6.1.6.Final"
ENV WINDUP_VERSION="6.2.0-SNAPSHOT"
ENV BUILD_ID="20230330.071913-130-with-authentication"
ENV DISTRIBUTION_DIR="dist"
# ENV JBOSS_CONTAINER_HOST="0.0.0.0"
# /6.2.0-SNAPSHOT/windup-web-distribution-6.2.0-.zip
# https://quay.io/repository/windupeng/windup-web-openshift?tab=tags
COPY ./${DISTRIBUTION_DIR}/windup-web-distribution-${WINDUP_VERSION}-${BUILD_ID}/ /tmp/app
EXPOSE 80 8080 8443 8042 9990 9993
CMD ["bash", "run_windup.sh"]