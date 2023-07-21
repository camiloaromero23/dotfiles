# FROM ubuntu:latest AS base
FROM ubuntu:latest AS base
WORKDIR /usr/local/bin
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common curl git build-essential && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y curl git ansible build-essential stow && \
    apt-get clean autoclean && \
    apt-get autoremove --yes

FROM base AS camilo
ARG TAGS
RUN addgroup --gid 1000 camilo
RUN adduser --gecos camilo --uid 1000 --gid 1000 --disabled-password camilo
USER camilo
WORKDIR /home/camilo/dotfiles

FROM camilo
COPY . .

