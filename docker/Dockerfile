FROM ubuntu:latest


# Requirements
SHELL ["/usr/bin/bash", "-c"]
RUN mkdir /_install && \
    yes | unminimize && \
    apt update && \
    apt install -y \
    rsync curl gnupg2 \
    python3 python3-venv python3-pip python3-apt


# VENV
RUN python3 -m venv --system-site-packages /_install/venv && \
    source /_install/venv/bin/activate && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN source /_install/venv/bin/activate && \
    ansible-playbook -e all=true /_install/docker.ansible.yml
SHELL ["/usr/bin/zsh", "-l", "-c"]
ENV TERM=xterm-256color
ENTRYPOINT ["/usr/bin/zsh", "-l"]
WORKDIR "/root"


# Bug
RUN apt install -o Dpkg::Options::="--force-overwrite" ripgrep


# Setup
RUN . "$XDG_CONFIG_HOME/tmux/bin/tmux-init" && \
    touch "$XDG_CACHE_HOME/zz" && \
    pip3 install ranger-fm pynvim && \
    python3 "$XDG_CONFIG_HOME/ranger/bin/plug.py" && \
    VIM_INIT=1 nvim --headless && \
    cd /_install && \
    wget https://github.com/romkatv/gitstatus/releases/download/v1.0.0/gitstatusd-linux-x86_64.tar.gz && \
    extract gitstatusd-linux-x86_64.tar.gz && \
    mkdir "$XDG_CACHE_HOME/gitstatus" && \
    mv gitstatusd-linux-x86_64 "$XDG_CACHE_HOME/gitstatus/"



# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/ansible /_install
