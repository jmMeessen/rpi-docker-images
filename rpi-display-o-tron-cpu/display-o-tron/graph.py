#!/usr/bin/env python

import dothat.backlight as backlight
#import dothat.lcd as lcd
import time

# Reset the LED states and polarity
backlight.graph_off()

# Dim the LEDs by setting the max duty to 1
backlight.graph_set_led_duty(0, 1)

# Now run a binary counter on the LEDs
while True:
    for x in range(64):
        for led in range(6):
            backlight.graph_set_led_state(led, x & (1 << led))
        time.sleep(0.1)

