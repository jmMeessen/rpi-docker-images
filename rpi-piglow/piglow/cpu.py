import signal
from time import sleep
import sys
from piglow import PiGlow
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
  piglow = PiGlow()
  while True:
    cpu = psutil.cpu_percent()
    piglow.all(0)

    if cpu < 5:
        piglow.red(20)
    elif cpu < 20:
        piglow.red(20)
        piglow.orange(20)
    elif cpu < 40:
        piglow.red(20)
        piglow.orange(20)
        piglow.yellow(20)
    elif cpu < 60:
        piglow.red(20)
        piglow.orange(20)
        piglow.yellow(20)
        piglow.green(20)
    elif cpu < 80:
        piglow.red(20)
        piglow.orange(20)
        piglow.yellow(20)
        piglow.green(20)
        piglow.blue(20)
    else:
        piglow.all(20)
    if killer.kill_now:
      break
    sleep(0.2)

  print "End of the program. I was killed gracefully :)"
  piglow.all(0)

