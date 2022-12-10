FROM ubuntu:latest

RUN apt-get update && \
  apt-get upgrade -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install --yes -- \
  openssh-client \
  python3 python3-pip && \
  python3 -m pip install --upgrade --no-cache-dir -- ansible && \
  mkdir --parents -- ~/.ssh

COPY . /srv
RUN mv -- ./id_rsa* ~/.ssh/ && \
  chmod 600 -- ~/.ssh/id_rsa*

WORKDIR /srv
ENTRYPOINT [ "ansible-playbook" ]
CMD [ "local.windows.yml" ]
