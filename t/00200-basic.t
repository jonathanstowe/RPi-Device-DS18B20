#!/usr/bin/env raku

use Test;
use RPi::Device::DS18B20;

my $device-dir = $*PROGRAM.parent.add('sys/bus/w1/devices').Str;

my $t;

lives-ok { $t = RPi::Device::DS18B20.new(:$device-dir, supply-interval => 0.5) }, "create ds18b20 object with mocked directory";

my @thermometers;

lives-ok { @thermometers = $t.thermometers }, "get thermometers";
is @thermometers.elems, 1, "got expected 1 thermometer";
my $therm = @thermometers[0];
isa-ok $therm, RPi::Device::DS18B20::Thermometer, "right object type";
is $therm.name, '28-012113620c31', "got expected name";
is $therm.temperature, 19.125, "and the expected temperature";

my $supply;

# In the real world this short an interval is pointless
lives-ok { $supply = $t.Supply(interval => 1) }, "Supply";

react {
    whenever $supply -> $reading {
        isa-ok $reading, RPi::Device::DS18B20::Reading, "got a Reading";
        is $reading.name, '28-012113620c31', "got expected name";
        is $reading.temperature, 19.125, "and the expected temperature";
        done;
    }
}

$device-dir = $*PROGRAM.parent.add('sys/bus/something/devices').Str;

throws-like { RPi::Device::DS18B20.new(:$device-dir).thermometers }, X::DS18B20::NoOneWire, "no device directory";

done-testing;

# vim: ft=raku
