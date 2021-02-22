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
    rm -rf /root/.ansible /_install && \
    apt install -y -o Dpkg::Options::="--force-overwrite" ripgrep && \
    /root/.config/tmux/bin/tmux-init && \
    /root/.config/nvim/init.py deps


SHELL ["/usr/bin/zsh", "-l", "-c"]
ENV TERM=xterm-256color \
    ISOCP_USE_FILE=1
ENTRYPOINT ["/usr/bin/zsh", "-l"]
WORKDIR "/root"


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/**
