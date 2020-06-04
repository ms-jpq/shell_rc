FROM ubuntu


# Requirements
SHELL ["/usr/bin/bash", "-c"]
RUN apt update && \
    apt install -y \
    python3-venv


# VENV
RUN mkdir /_install && \
    python3 -m venv /_install/venv && \
    source /_install/venv/bin/activate && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN source /_install/venv/bin/activate && \
    ansible-playbook -e all=true /_install/docker.ansible.yml
