FROM ubuntu:latest

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes -- \
  make \
  rsync \
  ca-certificates \
  git

WORKDIR /srv
COPY . /srv

RUN ./main.sh localhost

# SHELL ["/usr/bin/zsh", "-l", "-c"]
# ENV TERM=xterm-256color \
#     ISOCP_USE_FILE=1
# ENTRYPOINT ["/usr/bin/zsh", "-l"]
