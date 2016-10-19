# Container image that uses Pimoroni's Piglow to show the cpu load

FROM thecaptainsshack/rpi-piglow

WORKDIR /root/
ADD ./piglow/ ./piglow/

WORkDIR /root/piglow
CMD ["python2", "./cpu.py"]

