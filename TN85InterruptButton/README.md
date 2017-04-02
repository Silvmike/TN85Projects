# (ATTiny85) InterruptButton

Just a simple push button switch based on external interrupt: switches led on button press, doesn't react not pressed.

Compilation is tested on Atmel Studio 7.0

Resulting hex was uploaded with command:
```
avrdude -c usbtiny -p attiny85 -v -U lfuse:w:0x62:m -U hfuse:w:0xd7:m -U efuse:w:0xff:m -U flash:w:$(TargetDir)$(TargetName).hex:i
```