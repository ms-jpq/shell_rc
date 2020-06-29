FROM msjpq/cli:base


# Requirements
RUN apt update && \
    apt upgrade -y && \
    yes | unminimize


# Setup
COPY . /_install
RUN source "$XDG_CONFIG_HOME/zsh/.zshrc" && \
    /_install/docker/full/setup.sh


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/ansible /_install
