FROM ubuntu


# Requirements
SHELL ["/usr/bin/bash", "-c"]
RUN apt update && \
    apt install -y python3


# VENV
RUN apt install -y python3-pip && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN ansible-playbook -e all=true /_install/docker.ansible.yml
