
FROM alexellis2/python-gpio-arm:armv6

WORKDIR /root/
ADD ./piglow/ ./piglow/

RUN apt-get -q update
RUN apt-get -qy install python-dev python-pip python-smbus python-psutil gcc make

RUN apt-get -qy remove python-dev gcc make && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get -qy clean all

WORkDIR /root/piglow
CMD ["python2", "./cpu.py"]

