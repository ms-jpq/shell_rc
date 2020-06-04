FROM ubuntu


# Requirements
SHELL ["/usr/bin/bash", "-c"]
RUN apt update && \
    apt install -y \
    rsync curl python3 python3-venv python3-apt


# VENV
RUN mkdir /_install && \
    python3 -m venv --system-site-packages /_install/venv && \
    source /_install/venv/bin/activate && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN source /_install/venv/bin/activate && \
    ansible-playbook -e all=true /_install/docker.ansible.yml
