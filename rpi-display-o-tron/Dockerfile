
FROM alexellis2/python-gpio-arm:armv6

MAINTAINER Jean-Marc MEESSEN <jean-marc@meessen-web.org>

WORKDIR /root/
RUN apt-get -q update && \
    apt-get -qy install python-dev python-pip python-smbus python-psutil gcc make && \
    pip install spidev && \
    pip install dot3k && \
    apt-get -qy remove python-dev gcc make && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get -qy clean all
