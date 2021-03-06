use IO::Socket;
use IO::Select;
package caddx;
my $sock;
my $sel;
my $caddx_listen;
sub BEGIN{

	$caddx_listen="127.0.0.1:5055";  # default, overrideable by .ini
	my $lib_motion =new Group;
	my $lib_zone8 =new Generic_Item;

	$lib_motion                           -> add($lib_zone8);
	&main::MainLoop_pre_add_hook( \&poll_caddx, 'persistent' );
}

#############################################
## udp_init will set up the udp listener.
##  this code used to run from BEGIN, but we need
##  to wait until main has loaded config_parms, so it
##  is now deferred to first time thru in poll.
#############################################
sub udp_init{
	if($main::config_parms{caddx_listen}){
		$caddx_listen=$main::config_parms{caddx_listen};
	}
	$sock=new IO::Socket::INET(LocalAddr=>$caddx_listen,
				Proto=>"udp");
	die "can't listen for udp: [$caddx_listen]" unless $sock;

	$sel = IO::Select->new();

           $sel->add($sock);
}
#############################################
## readd:
##  select has reported a udp msg ready, so
##    lets see what it is.
#############################################
sub read{
	my $data;

        foreach my $fh ($sel->can_read(0)){

		$fh->recv($data,1000,0);
	}
	return $data;
}
#############################################
## poll_caddx is installed as a hook in mh
##  so that we can keep an eye on the udp 
##  msgs w/o modifying any user code.
#############################################
sub poll_caddx{
	
	&udp_init() unless ($sock);   ## need to wait for config_parms

	while($data=&caddx::read()){
		my $tag;
		my @pairs=split(/&/,$data);
		foreach my $pair (@pairs){
			my ($key,$val)=split(/=/,$pair);
			$tag->{$key}=$val;
		}
		
		&process_msg($tag);

	} #while
} #sub
#############################################
## process_msg will lookup the zone/partition
##  related to the msg, and modify the object
##  to reflect the new value reported by the caddx controller.
#############################################
sub process_msg{
	my($msg)=@_;
	my $obj;
	if($msg->{zone}){
		print     "zone: $msg->{zone} faulted: $msg->{faulted}" if $main::Debug{caddx};
		$obj=&Sensor_Zone::get_object_by_zone($msg->{zone});

		return unless($obj);   ## can't process if no object
                if($msg->{faulted}){
                        set $obj 'on';
                }
                else{
                        set $obj 'off';
                }
	}
	#If it is a partition message set stay or armed
	################
	##  Partition s/b a unique object type with it's own elements
	##   (stay/armed...), this is a hack that will track the status
	##   of various partitions as zone objects, with the partition
	##   number saved as part of the zone name:-(
	################
	if(length($msg->{partition}) > 0 ){
		print"Partition Message: Partition $msg->{partition}: Armed $msg->{armed} : Stay $msg->{stay}" if $main::Debug{caddx};
		my $prttn=$msg->{partition};

		# compare with null because we need to process a value of 0
		if($msg->{armed} cmp ""){
			print  "ARMED: $msg->{partition} armed: $msg->{armed}" if $main::Debug{caddx};
			$obj=&Sensor_Zone::get_object_by_zone('armed_' . $prttn);
			return unless($obj);   ## can't process if no object

			if($msg->{armed}){
				set $obj 'on';
			}
			else{
				set $obj 'off';
			}
		}

		# compare with null because we need to process a value of 0
		if($msg->{stay} cmp ""){
			print  "STAY: $msg->{partition} stay: $msg->{stay}" if $main::Debug{caddx};
			$obj=&Sensor_Zone::get_object_by_zone('stay_' . $prttn);
			return unless($obj);   ## can't process if no object

		       if($msg->{stay}){
			       set $obj 'on';
		       }
		       else{
			       set $obj 'off';
		       }
	       }
	}


}
package Sensor_Zone;
@ISA = ('Generic_Item');
my %zone_xref;
sub new {
	my ($class, $zone,$delay) = @_;

	# call the base constructor
	my $self = Generic_Item->new;


	## delay is useful for motion zones, where we should consider the
	##   motion to continue for "delay" seconds, even if the motion
	##   detector resets.
	if($delay){
		$self->{sensor_delay}=$delay;
	}
	$zone_xref{$zone}=$self;  # stash away reference by zone 
	return bless $self, $class;
}
###########################################
##  Give the users an xref to find a zone
##    if they just know the zone number.
###########################################
sub get_object_by_zone  {
	my ($zone)=@_;
	my $obj=$zone_xref{$zone};

	print " get_object_by_zone: $zone  $obj \n" if $main::Debug{caddx};
	return($zone_xref{$zone});
}
sub default_setstate{
	my ($self,$state)=@_;
	if(exists $self->{timer}){
		print " Sensor_Zone $self->{object_name} is timed! \n" if $main::Debug{caddx};
	}

	if (exists $self->{sensor_delay}){
		# if we're turning off (and not already in quiesce mode)
		my $sn=$self->state();
	      print " caddx set $self->{object_name}: from: state_now [$sn] to: $state\n" if $main::Debug{caddx};
		if($state=~/off/i && $self->state() =~ /on/i){ 
			  print " caddx set $self->{object_name} deferring: $state \n" if $main::Debug{caddx};
			$self->set_with_timer("quiescent",$self->{sensor_delay});
			return;
		}
		else{
			## we're about to transition the state... 
			## make sure the timer is idle.
			if(exists $self->{timer} 
			&& defined $self->{timer}
			&& active {$self->{timer}}){
				print " caddx unset timer! \n" if $main::Debug{caddx};
				unset {$self->{timer}};
			}
		}
	}
	
	## if we're still here, just fall thru to base class set (ON or OFF)
	print " caddx set $self->{object_name} invoking SUPER: $state \n" if $main::Debug{caddx};
	#$self->SUPER::set($state);
}
1;
