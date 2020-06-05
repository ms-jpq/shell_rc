FROM ubuntu


# Requirements
SHELL ["/usr/bin/bash", "-c"]
RUN yes | unminimize
RUN apt update && \
    apt install -y \
    rsync curl gnupg2 \
    python3 python3-venv python3-apt


# VENV
RUN mkdir /_install && \
    python3 -m venv --system-site-packages /_install/venv && \
    source /_install/venv/bin/activate && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN source /_install/venv/bin/activate && \
    ansible-playbook -e all=true /_install/docker.ansible.yml
WORKDIR "/WORK"
ENTRYPOINT ["/usr/bin/zsh"]


# Bug
RUN apt install -o Dpkg::Options::="--force-overwrite" ripgrep


# Setup
RUN apt install python3-pip && \
    pip3 install ranger-fm && \
    curl --create-dirs /root/.config/nvim/bin/plug.vim \
    "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/ansible /_install
