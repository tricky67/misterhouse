=begin comment

X10_RF_digimax.pm

This module contains routines called by X10_RF.pm to determine if a
group of RF data bytes represents a valid Digimax 210 command and
to decompose that data and set the state of the specific Digimax 210
specified by the command to the state specified by the command.

The Digimax 210 is a thermostat that sends X10 commands, via RF, to
a base unit that connects up to a heating & A/C unit to control the
unit wirelessly.  It seems to be primarily sold in Europe.

Chris Barrett/Bill Young

=cut

use strict;

package X10_RF;

use X10_RF;

#------------------------------------------------------------------------------

# Subroutine: rf_is_digimax210
#	Determine if <bytes> represents a valid Digimax 210 style command.

sub rf_is_digimax210 {
    my(@bytes) = @_;

    my @rbytes;
    for (my $i = 0; $i < 4; $i++) {
	$rbytes[$i] = ord(pack("b8", unpack("b*", $bytes[$i])));
    }

    return (   (   ($rbytes[2] == 0x1e)		# state = fan on
		|| ($rbytes[2] == 0x2d)		# state = fan off
		|| ($rbytes[2] == 0x3c))	# state = initialising 
	    && (   ($rbytes[3] >=  0  )		# temp between 0 and
		&& ($rbytes[3] <= 40  )));	#   40 degrees Celcius
}

#------------------------------------------------------------------------------

# Subroutine: rf_process_digimax210
#	Given a valid Digimax 210 style command in <bytes>, set the state
#	of Digimax 210 specified by the command to the state specfied by
#	the command.
#	<module> indicates the source of the request (w800)

sub rf_process_digimax210 {
    my($module, @bytes) = @_;

    # It appears that the bytes returned by the W800RF32AE for the Digimax 210
    # thermostat do not need as much conversion. Bytes 0&1 are the ID, 2 is the
    # status and 3 is the current temperature.  Unfortunately the setpoint set
    # on the Digimax's interface is not available via the W800RF32AE. (Chris
    # Barrett)
    my @rbytes;
    for (my $i = 0; $i < 4; $i++) {
	$rbytes[$i] = ord(pack("b8", unpack("b*", $bytes[$i])));
    }

    my($cmd, $device_id, $state);
    my($temperature);

    # Unlike other X-10 security devices, the Digimax's ID is 2 bytes long
    $device_id = $rbytes[0] * 256 + $rbytes[1];

    if ($rbytes[2] == 0x1e) {
	$state = "fan on";
    } elsif ($rbytes[2] == 0x2d) {
	$state = "fan off";
    } elsif ($rbytes[2] == 0x3c) {
	$state = "initialising";
    } else {
	$state = "unknown";	# this is redundant because of the test above.
    }

    $temperature = $rbytes[3];

    # I'm not sure if this is the right way to do this.  It means that
    # state and state_now will return "status:temperature", for example, if
    # the fan is off and it's 26C then state* will return "fan off:26"
    $state .= ":".$temperature;

    my $item_id  = lc sprintf "%04x", $device_id;

    # Set the state of any items or classes associated with this device.
    &rf_set_RF_Item($module, "digimax210", "unmatched device 0x$item_id",
		    $item_id, undef, $state);

    return $state;
}

#------------------------------------------------------------------------------

#
# $Log$
# Revision 1.1  2004/03/23 02:27:09  winter
# *** empty log message ***
#
#

# vim: sw=4

1;

