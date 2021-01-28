FROM ubuntu:latest


# Requirements
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
    rsync curl gnupg2 \
    python3 python3-venv python3-apt nodejs npm


# INSTALL
COPY . /_install
RUN python3 -m venv --system-site-packages /_install/venv && \
    PATH="/_install/venv/bin:$PATH" pip3 install ansible && \
    PATH="/_install/venv/bin:$PATH" ansible-playbook /_install/docker.ansible.yml && \
    rm -rf /_install
SHELL ["/usr/bin/zsh", "-l", "-c"]
ENV TERM=xterm-256color \
    ISOCP_USE_FILE=1
ENTRYPOINT ["/usr/bin/zsh", "-l"]
WORKDIR "/root"


# Bug
RUN apt install -y -o Dpkg::Options::="--force-overwrite" ripgrep


# Setup
RUN source "$XDG_CONFIG_HOME/zsh/.zshrc" && \
    /_install/docker/base/setup.sh


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/**
