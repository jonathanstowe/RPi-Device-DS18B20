class RPi::Device::DS18B20 {

    #| The path in the sysfs where the 1-Wire bus devices reside
    has Str $.device-dir    = "/sys/bus/w1/devices";
    #| The device "family code" as a string
    has Str $.device-class  = "28";
    has Str $.slave-node    = "w1_slave";

    #| default sampling interval for Supply
    has Int $.supply-interval = 30;

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
            $.device-dir.IO.dir( test => { .starts-with( $!device-class ) }).grep( -> $d { $d.add($!slave-node).e }).map( -> $device-path { Thermometer.new(:$device-path) });
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
