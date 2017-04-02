# (ATTiny85) Blinker

Just a simple blinker on AVR with 1 second (on int. oscill. 1 Mhz) delay between led switches.

Compilation is tested on Atmel Studio 7.0

Resulting hex was uploaded with command:
```
avrdude -c usbtiny -p attiny85 -v -U lfuse:w:0x62:m -U hfuse:w:0xd7:m -U efuse:w:0xff:m -U flash:w:$(TargetDir)$(TargetName).hex:i
```