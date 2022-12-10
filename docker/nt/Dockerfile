FROM python:latest

RUN python3 -m pip install --upgrade --no-cache-dir -- ansible
COPY . /srv

WORKDIR /srv
ENTRYPOINT [ "ansible-playbook" ]
CMD [ "local.windows.yml" ]
