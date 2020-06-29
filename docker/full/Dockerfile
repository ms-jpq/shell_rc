FROM msjpq/cli:base


# Bug
RUN apt remove ripgrep


# Requirements
RUN apt update && \
    apt upgrade -y && \
    yes | unminimize


# Bug
RUN apt install -o Dpkg::Options::="--force-overwrite" ripgrep


# Setup
COPY . /_install
RUN source "$XDG_CONFIG_HOME/zsh/.zshrc" && \
    /_install/docker/full/setup.sh


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/ansible /_install
