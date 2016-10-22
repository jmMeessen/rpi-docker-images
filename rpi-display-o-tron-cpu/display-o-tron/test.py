#!/usr/bin/env python

import dothat.backlight as backlight
#import dothat.lcd as lcd
#import time
import signal
from time import sleep
import sys
import psutil

# Reset the LED states and polarity
backlight.graph_off()

backlight.graph_set_led_duty(0, 1)

backlight.set_graph(1)
