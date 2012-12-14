RGBU_light
==========

4 channel R-G-B-U light effect modules with control from PC

source language: Delphi, Atmel assembler.
Hardware       : MASTER module - ATMEGA8,
                 SLAVE modules - ATTINY13.

Can be extended up to 254 4-channel modules to one master. Theoretical update speed - up to 400 modules per seconds, but on practice - about 100 per second.
It`s potential to speed-up x2 faster by using 9.6Mhz clock source in modules and some modification in sources of master module.

How its work?

It is Applicaton on PC that sends channels data to MASTER module throw USB-UART or Bluetooth-UART or RS232-UART bridge.
Master module synchronize SLAVE modules and retransmitt commands to each modules, whith connected by 3-wire line(2x Power and 1x Data).
Each module, if math it adress, receive each channel value and apply to 4-CH 8bit PWM output.

Slave modules don`t have quartz crystal, it working on built-in RC-generator and stay working with +-10...15% speed deviation.
In most cases there is no need to calibrate but recommended.
