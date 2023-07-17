FROM ubuntu:latest

# hadolint ignore=DL3009
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes -- \
  make \
  rsync

WORKDIR /srv
COPY . /srv

RUN ./main.sh localhost && \
  apt-get clean && \
  rm -rf -- /srv/* /var/lib/apt/lists/* /var/tmp/* /tmp/*

ENV TERM=xterm-256color \
  ISOCP_USE_FILE=1
WORKDIR "$HOME"
ENTRYPOINT ["/usr/bin/zsh", "-l"]
