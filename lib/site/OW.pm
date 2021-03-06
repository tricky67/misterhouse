# This file was automatically generated by SWIG (http://www.swig.org).
# Version 1.3.33
#
# Don't modify this file, modify the SWIG interface instead.

package OW;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
package OWc;
bootstrap OW;
package OW;
@EXPORT = qw( );

# ---------- BASE METHODS -------------

package OW;

sub TIEHASH {
    my ($classname,$obj) = @_;
    return bless $obj, $classname;
}

sub CLEAR { }

sub FIRSTKEY { }

sub NEXTKEY { }

sub FETCH {
    my ($self,$field) = @_;
    my $member_func = "swig_${field}_get";
    $self->$member_func();
}

sub STORE {
    my ($self,$field,$newval) = @_;
    my $member_func = "swig_${field}_set";
    $self->$member_func($newval);
}

sub this {
    my $ptr = shift;
    return tied(%$ptr);
}


# ------- FUNCTION WRAPPERS --------

package OW;

*version = *OWc::version;
*init = *OWc::init;
*get = *OWc::get;
*put = *OWc::put;
*finish = *OWc::finish;
*set_error_print = *OWc::set_error_print;
*get_error_print = *OWc::get_error_print;
*set_error_level = *OWc::set_error_level;
*get_error_level = *OWc::get_error_level;

# ------- VARIABLE STUBS --------

package OW;

1;
