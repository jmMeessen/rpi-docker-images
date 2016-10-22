#!/usr/bin/env python

import dothat.backlight as backlight
#import dothat.lcd as lcd
#import time
import signal
from time import sleep
import sys
import psutil

class GracefulKiller:
  kill_now = False
  def __init__(self):
    signal.signal(signal.SIGINT, self.exit_gracefully)
    signal.signal(signal.SIGTERM, self.exit_gracefully)

  def exit_gracefully(self,signum, frame):
    self.kill_now = True


if __name__ == '__main__':
  killer = GracefulKiller()
  
  # Reset the LED states and polarity
  backlight.graph_off()
  
  # Dim the LEDs by setting the max duty to 1
  backlight.graph_set_led_duty(0, 1)
  
  while True:
    cpu = psutil.cpu_percent()
    backlight.graph_off()

    if cpu < 5:
        backlight.set_graph(1)
    elif cpu < 20:
        backlight.set_graph(2)
    elif cpu < 40:
        backlight.set_graph(3)
    elif cpu < 60:
        backlight.set_graph(4)
    elif cpu < 80:
        backlight.set_graph(5)
    else:
        backlight.set_graph(6)
    if killer.kill_now:
      break
    sleep(0.2)


