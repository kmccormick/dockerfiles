FROM ubuntu:trusty
# Dockerfile to run a self-hosted Syncthing discovery server.
MAINTAINER Scott Hansen <firecat4153@gmail.com>

ADD https://github.com/syncthing/discosrv/releases/download/v0.12.2/discosrv-linux-amd64.tar.gz /discosrv.tar.gz
RUN tar -xzvf discosrv.tar.gz && rm discosrv.tar.gz && mv discosrv* discosrv
RUN useradd --no-create-home -g users --uid 22000 syncthing
RUN mkdir /var/discosrv && chown syncthing: /var/discosrv

USER syncthing

ENTRYPOINT ["/discosrv/discosrv"]
