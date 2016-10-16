#!/bin/bash

if [ ! -d unicorn-hat ];
then
   git clone https://github.com/pimoroni/piglow.git
fi

docker build -t piglow .

