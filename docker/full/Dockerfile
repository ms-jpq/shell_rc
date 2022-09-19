FROM msjpq/cli:base


# Requirements
RUN apt-get update && \
    apt-get upgrade --yes


RUN source "$XDG_CONFIG_HOME/zsh/rc.d/.zshrc" && \
    /root/setup.sh


# Cleanup
RUN apt-get autoremove --yes && \
    apt-get clean && \
    rm -rf -- /tmp/ansible /_install
