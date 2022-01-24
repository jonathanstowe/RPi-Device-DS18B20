=begin pod

=head1 NAME

RPi::Device::DS18B20 - Interface to the DS18B20 digital thermometer from Maxim Integrated

=head1 SYNOPSIS

=begin code
use RPi::Device::DS18B20;

my $t = RPi::Device::DS18B20.new;

for $t.thermometers -> $thermometer {
    say $thermometer.name, ":\t", $thermometer.temperature;
}
=end code

Or asynchronously:

=begin code
use RPi::Device::DS18B20;

my $t = RPi::Device::DS18B20.new;

react {
    whenever $t -> $reading {
        say $reading.when, "\t", $reading.name, "\t", $reading.temperature;
    }
}
=end code

The source is in the L<examples|examples> directory of the distribution.

=head1 DESCRIPTION

The L<DS18B20|https://www.maximintegrated.com/en/products/sensors/DS18B20.html> is a handy and inexpensive digital thermometer that uses the L<Dallas 1-Wire bus|https://en.wikipedia.org/wiki/1-Wire>.

The Linux kernel has support for 1-Wire which can be enabled with `raspi-config` (via `Interface Options -> 1-Wire`,) which by default enables the 1-Wire interface on GPIO 4 as per:

L<Raspberry Pi GPIO pins|https://www.raspberrypi.com/documentation/computers/images/GPIO-Pinout-Diagram-2.png>

It can be configured on another pin (or pins,) as described L<here|https://blog.oddbit.com/post/2018-03-27-multiple-1-wire-buses-on-the/>

Each thermometer has a unique identifer (in common with all 1-Wire sensors,) which means that multiple thermometers can be used on the same bus at once, however there is no way of distinguishing the devices without querying them, so a programme may need to provide its own mapping of identifier to thermometer (location etc,) this can be achieved by either wiring them in one by one, running something like the synopsis code and noting the identifier (and presumably labelling the sensor,) or by applying some heat source to each one in turn (if you have one of the encapsulated "waterproof" sensors a cup of hot water is ideal, but holding the sensor in your hand should work if the ambient temperature is lower than body temparature,) and similarly noting the identifier.

The module provides for the enumeration of the thermometers detected on the 1-Wire bus providing a list of C<Thermometer> objects, having a C<name> attribute and a C<temperature> method that returns the degrees Celcius with a precision of a thousandth of a degree (though the device is commonly stated as having ±0.5⁰ accuracy so this precision may or may not be useful to you.)  The default "conversion time" for the device is 750 milliseconds so requesting the temperature more frequently than that is likely to be fruitless.

Alternatively  the C<RPi::Device::DS18B20> object provides a C<Supply> "coercion" method which allows it be used anywhere a C<Supply> can be used (such as a C<whenever> in a C<react> block,) this will emit a `Reading` object with a C<name> attribute of the sensor id, a C<temperature> attribute with the measured temperature and a C<when> attribute, for every sensor detected at minimum frequency determined by the C<supply-interval> attribute as supplied to the constructor (the default is 30 seconds.) The readings may not be emitted in a predictable order at each interval as each sensor may take a different length of time to produce a reading, plus the bus protocol will, by necessity, serialise the readings.


=end pod

#| The class that models the interface to the 1-Wire thermometer.
#| None of the attributes are required by the constructor.
class RPi::Device::DS18B20 {

    #| The path in the sysfs where the 1-Wire bus devices reside
    #| The default should always work, it's really only exposed for testing.
    has Str $.device-dir    = "/sys/bus/w1/devices";
    #| The device "family code" as a string
    has Str $.device-class  = "28";
    has Str $.slave-node    = "w1_slave";

    #| default sampling interval for Supply in seconds. The default is 30 seconds.
    #| Please see the note above about the likely minimum practical value.
    has Numeric $.supply-interval = 30;

    #| The exception thrown when there is no 1-Wire bus entry in the sysfs
    class X::DS18B20::NoOneWire is Exception {
        method message( --> Str ) {
            "No 1-wire devices - did you forget to enable the 1-wire interface";
        }
    }

    #| Returns a boolean to indicate the 1-Wire protocol is configured
    method check-one-wire( --> Bool ) {
        $.device-dir.IO.d;
    }

    #| The class describing an individual thermometer sensor
    #| These will be instantiated by the "thermometers" method
    #| as necessary.  The 'device-path' is required.
    class  Thermometer {

        #| The directory path to the sysfs entry for the sensor
        has IO::Path $.device-path is required;

        #| The "name" of the sensor, this is the unique id prefixed by the "family code"
        has Str $.name;

        method name( --> Str ) {
            $!name //= do {
                $!device-path.add('name').slurp.chomp;
            }
        }

        #| Returns the temperature recorded by the sensor in degrees Celcius.
        #| this can be called repeatedly to return a new reading.
        method temperature(--> Numeric ) {
            $!device-path.add('temperature').slurp.chomp.Int / 1000.00;
        }
    }

    #| Returns a list of the sensors on the bus as Thermometer objects
    #| It will throw X::DS18B20::NoOneWire if the 1-Wire bus interface isn't configured
    method thermometers() {
        if $.check-one-wire {
            $.device-dir.IO.dir( test => { .starts-with( $!device-class ) }).grep( -> $d { $d.add($!slave-node).e }).map( -> $device-path { Thermometer.new(:$device-path) }).list;
        }
        else {
            X::DS18B20::NoOneWire.new.throw;
        }
    }

    #| The class representing a single reading from a single sensor from the Supply interface
    class Reading {
        #| The underlying Thermometer object from which the reading was taken. This provides the delegated 'name' attribute
        has Thermometer $.thermometer is required handles <name>;
        #| The recorded temperature at the time the reading was taken
        has Numeric     $.temperature is required;
        #| The actual DateTime when the reading was taken
        has DateTime    $.when        = DateTime.now;
    }

    #| A Supply on to which Reading objects are emitted for each sensor at a minimum frequency as specified by the supply-interval
    #| supplied to the constructor as seconds (with a default of thirty.) Because the default "conversion time" of the sensors is
    #| 750 milliseconds and the actual time taken to return a reading may vary with the number of sensors and other physical factors
    #| you may need to determine the minimum useful interval by experimentation, but it's likely to be a second or above,
    method Supply(:$interval = $!supply-interval --> Supply ) {
        supply {
            for $.thermometers.list -> $thermometer {
                whenever Supply.interval($interval) {
                    emit Reading.new(:$thermometer, temperature => $thermometer.temperature);
                }
            }

        }
    }
}

# vim: ft=raku
