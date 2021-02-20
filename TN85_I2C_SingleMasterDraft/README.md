# (ATTiny85) I2C SingleMaster (Draft)

This is just an example of I2C single master implementation with USI.

Resulting hex was uploaded with command:
```
avrdude -c usbtiny -p attiny85 -v -U lfuse:w:0x62:m -U hfuse:w:0xd7:m -U efuse:w:0xff:m -U flash:w:$(TargetDir)$(TargetName).hex:i
```

## Results

Simulation in Proteus (there is no slave device):

![Proteus simulation](https://github.com/Silvmike/TN85Projects/blob/master/TN85_I2C_SingleMasterDraft/proteus_digital_analyzer.png?raw=true)

Capture using logical analyzer (USBee clone + Sigrok PulseView, with slave device on address 0x3C):

![Proteus simulation](https://github.com/Silvmike/TN85Projects/blob/master/TN85_I2C_SingleMasterDraft/log_analyzer.png?raw=true)
