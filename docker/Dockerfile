FROM ubuntu


ARG S6_VER="2.0.0.1"
ARG TTYD_VER="1.6.0"


## S6 Overlay
RUN mkdir /_install
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_VER}/s6-overlay-amd64.tar.gz /_install
RUN tar xzf /_install/s6-overlay-amd64.tar.gz -C / --exclude="./bin" && \
    tar xzf /_install/s6-overlay-amd64.tar.gz -C /usr ./bin
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENTRYPOINT ["/init"]


# TTYd
ADD https://github.com/tsl0922/ttyd/releases/download/${TTYD_VER}/ttyd_linux.x86_64 /_install
COPY docker/root /
RUN chmod +x /_install/ttyd_linux.x86_64 && \
    mv /_install/ttyd_linux.x86_64 /usr/local/bin/ttyd
EXPOSE 8080
ENV FONT_SIZE=16


# Requirements
SHELL ["/usr/bin/bash", "-c"]
RUN yes | unminimize && \
    apt update && \
    apt install -y \
    rsync curl gnupg2 \
    python3 python3-venv python3-pip python3-apt


# VENV
RUN python3 -m venv --system-site-packages /_install/venv && \
    source /_install/venv/bin/activate && \
    pip3 install ansible


# INSTALL
COPY . /_install
RUN source /_install/venv/bin/activate && \
    ansible-playbook -e all=true /_install/docker.ansible.yml
SHELL ["/usr/bin/zsh", "-l", "-c"]
ENV TERM=xterm-256color


# Bug
RUN apt install -o Dpkg::Options::="--force-overwrite" ripgrep


# Setup
RUN . "$XDG_CONFIG_HOME/tmux/bin/tmux_init" && \
    pip3 install ranger-fm pynvim && \
    touch "$XDG_CACHE_HOME/zz"


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/ansible /_install
