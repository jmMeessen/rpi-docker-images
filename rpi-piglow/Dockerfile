
FROM alexellis2/python-gpio-arm:armv6

WORKDIR /root/
ADD ./piglow/ ./piglow/

RUN apt-get -q update
RUN apt-get -qy install python-dev python-pip gcc make
RUN pip install rpi-ws281x 
RUN pip install Piglow
  
RUN apt-get -qy remove python-dev gcc make && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get -qy clean all

#CMD ["python2", "./piglow/python/examples/cycle.py"]

