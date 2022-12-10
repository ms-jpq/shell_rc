FROM python:latest

RUN python -m pip install --upgrade --no-cache-dir -- ansible
COPY . /srv

WORKDIR /srv
ENTRYPOINT [ "ansible-playbook" ]
CMD [ "local.windows.yml" ]
