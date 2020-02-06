FROM maven:3.6.3-jdk-8-slim

MAINTAINER Jan Forberg <forberg@infai.org>

RUN apt-get update
RUN apt-get install raptor2-utils -y

COPY . /src
WORKDIR /src


ENTRYPOINT /bin/bash run.sh
