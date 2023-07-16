FROM ubuntu:latest

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes -- \
  make \
  rsync

WORKDIR /srv
COPY . /srv

RUN make all

# SHELL ["/usr/bin/zsh", "-l", "-c"]
# ENV TERM=xterm-256color \
#     ISOCP_USE_FILE=1
# ENTRYPOINT ["/usr/bin/zsh", "-l"]
