# RPi::Device::DS18B20

Interface to the DS18B20 digital thermometer from Maxim Integrated

## Synopsis

```raku
use RPi::Device::DS18B20;

....
```

## Description

The [DS18B20](https://www.maximintegrated.com/en/products/sensors/DS18B20.html) is a handy and inexpensive digital thermometer that uses the (Dallas 1-Wire bus)[https://en.wikipedia.org/wiki/1-Wire].

The Linux kernel has support for 1-Wire which can be enabled with `raspi-config` (via `Interface Options -> 1-Wire`,) which by default enables the 1-Wire interface on GPIO 4 as per:

![Raspberry Pi GPIO pins](https://www.raspberrypi.com/documentation/computers/images/GPIO-Pinout-Diagram-2.png)

It can be configured on another pin (or pins,) as described [here](https://blog.oddbit.com/post/2018-03-27-multiple-1-wire-buses-on-the/)

## Install

Assuming you have a working copy of Rakudo you can install with *zef* :

```
zef install RPi::Device::DS18B20
```
It is unlikely to work on anything else than a Raspberry Pi.

##  Support

This is difficult to test in a completely automated fashion without the actual device attached and knowing what the temparature should be so there may be bugs which I haven't noticed.

Please send any patches/suggestions/issues via [Github](https://github.com/jonathanstowe/RPi-Device-DS18B20/issues). 

Ideally any reports should include the Raspberry Pi and OS versions and some indication of how the device was wired up.

## Copyright & Licence

This is free software, please see the [LICENCE](LICENCE) in the distribution.

© Jonathan Stowe 2022
