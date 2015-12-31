FROM ubuntu:trusty

#MAINTAINER Scott Hansen <firecat4153@gmail.com>
MAINTAINER https://github.com/kmccormick/dockerfiles

RUN apt-get -q update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        deluge-console \
        deluge-web \
        deluged \
        jq \
        openvpn \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo America/Los_Angeles > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

ENV DELUGE_USER=deluge DELUGE_GROUP=deluge \
    DELUGE_UID=22000 DELUGE_GID=22000

RUN groupadd --gid $DELUGE_GID $DELUGE_GROUP
RUN useradd --no-create-home -g $DELUGE_GROUP --uid $DELUGE_UID $DELUGE_USER

COPY pia-deluge.sh /pia-deluge.sh
COPY private/deluge /config/deluge
COPY private/openvpn /config/openvpn

VOLUME /config

CMD ["/pia-deluge.sh"]
