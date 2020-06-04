FROM ubuntu


SHELL ["/usr/bin/bash", "-c"]
RUN apt update && \
    apt install -y python3-pip


COPY . /_install
RUN python3 -m venv /_install/venv && \
    source /_install/venv/bin/activate && \
    pip3 install ansible


RUN ansible-playbook -e all=true /_install/docker.ansible.yml
