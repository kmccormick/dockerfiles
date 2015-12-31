FROM ubuntu:trusty

#MAINTAINER Scott Hansen <firecat4153@gmail.com>
MAINTAINER https://github.com/kmccormick/dockerfiles

RUN apt-get -q update && \
    apt-get install -y curl jq \
    openvpn deluged deluge-console deluge-web

RUN echo America/Los_Angeles > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

ENV DELUGE_USER deluge
ENV UID 22000
ENV DELUGE_GROUP deluge
ENV GID 22000
RUN groupadd --gid $GID $DELUGE_GROUP
RUN useradd --no-create-home -g $DELUGE_GROUP --uid $UID $DELUGE_USER

COPY pia-deluge.sh /pia-deluge.sh
COPY private/deluge /config/deluge
COPY private/openvpn /config/openvpn

VOLUME /config

CMD ["/pia-deluge.sh"]
