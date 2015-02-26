# MD-81
#
# Pneumatic support routines
#
# Gary Neely aka 'Buckaroo'
#
# This system provides support for the pneumatic system. In effect it's handled similar to a
# simplified version of the electrical system: essentialy there are suppliers and drains, and
# currently the system just determines if a supply is available to support one or more drains.
#
# There are 3 possible feeds for the system: the left engine, the right engine, and the apu.
# The engines support their own sub-systems, and can feed into the common system or bus. The apu
# feeds only the common system.
#
# Good PSI on the common bus should be around 35. I assume there are relief valves in the system,
# but I allow the pressure to vary a bit based on the number of contributing feeds. I could do
# do this based on source feed values, but it's just easier to give ballpark numbers. This is
# conjecture-- other than the good value of >=35 PSI, I have no idea how this behaves.
#


var MIN_PSI		= 35;						# Good common PSI level
var NUM_ENGINES		= 2;
var PNEU_UPDATE_PERIOD	= 1;						# Once per second is good enough

									# Handy handles for source feed indices
var pneu_feed	= {	eng1	: 0,
			eng2	: 1,
			apu	: 2
		  };
var pneu_feeds	= [0,0,0];						# For fast feed checking
var psi_list	= [0,35,37,40];						# PSI based on number of sources
var psi_current	= 0;
var psi_target	= 0;

									# Other property handles:
var engines	= props.globals.getNode("/engines").getChildren("engine");
#var sources	= props.globals.getNode("/systems/pneumatic").getChildren("source");
var pneu_psi	= props.globals.getNode("/systems/pneumatic/psi");
var sw_air_eng	= props.globals.getNode("/controls/pneumatic").getChildren("engine");
#var sw_air_apu	= props.globals.getNode("/controls/pneumatic/APU-bleed");
var apu_running	= props.globals.getNode("/systems/apu/running");
var apu_air	= props.globals.getNode("/systems/apu/air");
var apu_state	= props.globals.getNode("/systems/apu/state");


#
# Primary pneumatic system support:
#

									# If an engine is running and the appropriate eng pneu
									# lever is on, indicate source is a supplier
var check_pneu_source_engines = func {
  for(var i=0; i<NUM_ENGINES; i+=1) {
    if (!engines[i].getNode("out-of-fuel").getValue() and
        sw_air_eng[i].getNode("bleed").getValue()) {
      pneu_feeds[i] = 1;
    }
    else {
      pneu_feeds[i] = 0;
    }
  }
}

var check_pneu_source_apu = func {					# APU must be running, warmed-up, and air on
  if (apu_running.getValue() and
      apu_state.getValue()==1 and
      apu_air.getValue()) {
    pneu_feeds[pneu_feed["apu"]] = 1;
  }
  else {
    pneu_feeds[pneu_feed["apu"]] = 0;
  }
}

var update_pneu_feeds = func {
  var feed_count = 0;							# We'll vary pressure slightly based on number of sources
  for(var i=0; i<size(pneu_feeds); i+=1) {				# Check all possible feeds
    if (pneu_feeds[i]) {						# If feed is on
      feed_count+=1;							# incrment feed count
    }
  }
									# Determine PSI based on number of contributing sources
									# Update only if different from previous
  if (psi_list[feed_count] != psi_current) {
    psi_target = psi_list[feed_count];
    interpolate(pneu_psi,psi_target,3);
    psi_current = psi_target;
  }
}


									# The master bus update system
var update_pneumatics = func {
  check_pneu_source_engines();
  check_pneu_source_apu();
  update_pneu_feeds();
  #update_pneu_outputs();
  settimer(update_pneumatics,PNEU_UPDATE_PERIOD);			# Schedule the next run
}




var pneumatics_setup = func {
									# Currently no initialization required
  settimer(update_pneumatics,1);					# Startup system
}


var PneumaticsInit = func {
  settimer(pneumatics_setup, 2);						# Give a few seconds for vars to initialize
}
