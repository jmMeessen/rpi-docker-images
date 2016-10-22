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
  
  backlight.graph_off()
  
  backlight.graph_set_led_duty(0, 1)
  
  while True:
    cpu = psutil.cpu_percent()
    backlight.graph_off()

    backlight.set_graph(cpu /100)

    if killer.kill_now:
      break
    sleep(0.3)


