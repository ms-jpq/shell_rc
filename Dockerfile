FROM ubuntu


# Requirements
SHELL ["/usr/bin/bash", "-c"]
RUN yes | unminimize && \
    apt update && \
    apt install -y \
    rsync curl gnupg2 \
    python3 python3-venv python3-pip python3-apt


# VENV
RUN mkdir /_install && \
    python3 -m venv --system-site-packages /_install/venv && \
    source /_install/venv/bin/activate && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN source /_install/venv/bin/activate && \
    ansible-playbook -e all=true /_install/docker.ansible.yml
SHELL ["/usr/bin/zsh", "-l", "-c"]
ENTRYPOINT ["/usr/bin/zsh"]
ENV TERM=xterm-256color
WORKDIR "/root/WORK"


# Bug
RUN apt install -o Dpkg::Options::="--force-overwrite" ripgrep


# Setup
RUN . "$XDG_CONFIG_HOME/tmux/bin/tmux_init" && \
    pip3 install ranger-fm pynvim && \
    touch "$XDG_CACHE_HOME/zz" && \
    source "$XDG_CONFIG_HOME/zsh/powerlevel10k/gitstatus/gitstatus.plugin.zsh" _p9k_


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/ansible /_install
