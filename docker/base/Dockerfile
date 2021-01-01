FROM ubuntu:latest


# Requirements
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
    rsync curl gnupg2 \
    python3 python3-pip python3-apt && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN ansible-playbook /_install/docker.ansible.yml
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
    rm -rf /tmp/** /_install
