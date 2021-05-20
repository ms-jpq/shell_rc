FROM msjpq/cli:base


# Bug
RUN apt remove -y ripgrep


# Requirements
RUN apt update && \
    apt upgrade -y && \
    yes | unminimize


RUN source "$XDG_CONFIG_HOME/zsh/rc/.zshrc" && \
    /root/setup.sh


# Cleanup
RUN apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/ansible /_install
