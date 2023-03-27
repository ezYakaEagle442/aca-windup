# DOCKER_BUILDKIT=0 DOCKER_DEFAULT_PLATFORM=linux/amd64 docker build --build-arg --no-cache -t "windup" -f "./src/Dockerfile" .
# docker tag windup acrwindupaca.azurecr.io/windup/windup
# docker push acrwindupaca.azurecr.io/windup/windup
# docker pull acrwindupaca.azurecr.io/windup/windup
# docker image ls | grep -i windup
# docker image prune"
# docker run -p 8080:8080 -p 9090:9090 -p 8042:8042 -p 9993:9993 -p 8443:8443 windup
# docker container ls
# docker ps
# docker exec -it <container-id> /bin/sh

# https://docs.microsoft.com/en-us/java/openjdk/containers

FROM mcr.microsoft.com/openjdk/jdk:11-mariner
LABEL Maintainer="pinpin <noname@microsoft.com>"
LABEL Description="Windup built from MS OpenJDK 11-Mariner"
RUN mkdir /tmp/app
WORKDIR /tmp/app
ENV WINDUP_VERSION="6.1.6"
ENV DISTRIBUTION_DIR="dist"
COPY ./${DISTRIBUTION_DIR}/windup-web-distribution-${WINDUP_VERSION}.Final/ /tmp/app
EXPOSE 80 8080 8443 8042 9090 9993
CMD ["bash", "run_windup.sh"]