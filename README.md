# RPi::Device::DS18B20

Interface to the DS18B20 digital thermometer from Maxim Integrated

[![CI](https://github.com/jonathanstowe/RPi-Device-DS18B20/actions/workflows/main.yml/badge.svg)](https://github.com/jonathanstowe/RPi-Device-DS18B20/actions/workflows/main.yml)

## Synopsis



```raku
use RPi::Device::DS18B20;

my $t = RPi::Device::DS18B20.new;

for $t.thermometers -> $thermometer {
    say $thermometer.name, ":\t", $thermometer.temperature;
}
```

Or asynchronously:

```raku
use RPi::Device::DS18B20;

my $t = RPi::Device::DS18B20.new;

react {
    whenever $t -> $reading {
        say $reading.when, "\t", $reading.name, "\t", $reading.temperature;
    }
}
```

The source is in the [examples](examples) directory of the distribution.

## Description

The [DS18B20](https://www.maximintegrated.com/en/products/sensors/DS18B20.html) is a handy and inexpensive digital thermometer that uses the (Dallas 1-Wire bus)[https://en.wikipedia.org/wiki/1-Wire].

The Linux kernel has support for 1-Wire which can be enabled with `raspi-config` (via `Interface Options -> 1-Wire`,) which by default enables the 1-Wire interface on GPIO 4 as per:

![Raspberry Pi GPIO pins](https://www.raspberrypi.com/documentation/computers/images/GPIO-Pinout-Diagram-2.png)

It can be configured on another pin (or pins,) as described [here](https://blog.oddbit.com/post/2018-03-27-multiple-1-wire-buses-on-the/)

Each thermometer has a unique identifer (in common with all 1-Wire sensors,) which means that multiple thermometers can be used on the same bus at once, however there is no way of distinguishing the devices without querying them, so a programme may need to provide its own mapping of identifier to thermometer (location etc,) this can be achieved by either wiring them in one by one, running something like the synopsis code and noting the identifier (and presumably labelling the sensor,) or by applying some heat source to each one in turn (if you have one of the encapsulated "waterproof" sensors a cup of hot water is ideal, but holding the sensor in your hand should work if the ambient temperature is lower than body temparature,) and similarly noting the identifier.

The module provides for the enumeration of the thermometers detected on the 1-Wire bus providing a list of `Thermometer` objects, having a name attribute and a `temperature` method that returns the degrees Celcius with a precision of a thousandth of a degree (though the device is commonly stated as having ±0.5⁰ accuracy so this precision may or may not be useful to you.)  The default "conversion time" for the device is 750 milliseconds so requesting the temperature more frequently than that is likely to be fruitless.

Alternatively  the `RPi::Device::DS18B20` object provides a `Supply` "coercion" method which allows it be used anywhere a `Supply` can be used (such as a `whenever` in a `react` block,) this will emit a `Reading` object with a `name` attribute of the sensor id, a `temperature` attribute with the measured temperature and a `when` attribute, for every sensor detected at minimum frequency determined by the `supply-interval` attribute as supplied to the constructor (the default is 30 seconds.) The readings may not be emitted in a predictable order at each interval as each sensor may take a different length of time to produce a reading, plus the bus protocol will, by necessity, serialise the readings. 

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

This may work with other 1-Wire thermometer sensors [supported by the Linux kernel](https://www.kernel.org/doc/html/latest/w1/slaves/w1_therm.html) by adjusting the `device-class` passed to the constructor, but as I don't have any to test with right now I can't make any guarantees, it also appears that DS18B20 is by far and away the most commonly used.

## Copyright & Licence

This is free software, please see the [LICENCE](LICENCE) in the distribution.

© Jonathan Stowe 2022
