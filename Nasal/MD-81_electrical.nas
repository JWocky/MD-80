# MD-81
#
# Electrical support routines
#
# Gary Neely aka 'Buckaroo'
#
# Primarily an AC system with DC needs provided by rectifiers.
# DC primarily services lights and control circuits.
# Battery is used mostly to start the APU or provide emergency power for about 0.5 hours.
# Battery consists of two 14V units in series for a 28V system.
#
# The current system is simplified to assume all power is derived from a single operating
# AC bus. Therefore the battery (for the moment) is listed as a 115V AC source.
#


var ELEC_UPDATE_PERIOD	= 0.5;						# A periodic update in secs
var STD_VOLTS_AC	= 115;						# Typical volts for a power source
var MIN_VOLTS_AC	= 115;						# Typical minimum voltage level for generic equipment
var STD_VOLTS_DC	= 28;						# Typical volts for a power source
var MIN_VOLTS_DC	= 25;						# Typical minimum voltage level for generic equipment
var STD_AMPS		= 0;						# Not used yet
var NUM_ENGINES		= 2;


									# Handy handles for DC source feed indices
var feed	= {	eng1	: 0,
			eng2	: 1,
			apu	: 2,
			batt	: 3,
			cart	: 4,
			rect1	: 5,
			rect2	: 6
		  };
var feed_status	= [0,0,0,0,0,0,0];					# For fast feed switch checking
var RECT_OFFSET = 5;							# Handy rectifier index offset

									# Other property handles:
var engines	= props.globals.getNode("/engines").getChildren("engine");
var sources	= props.globals.getNode("/systems/electrical").getChildren("power-source");
var apu_running	= props.globals.getNode("/systems/apu/running");
var sw_batt	= props.globals.getNode("/controls/switches/battery");
var sw_cart	= props.globals.getNode("/controls/switches/cart");
var cart_wow	= props.globals.getNode("/gear/gear[0]/wow");
var gndspd	= props.globals.getNode("velocities/groundspeed-kt",1);
var sw_gen	= props.globals.getNode("/controls/switches").getChildren("generator");
var test_dc	= props.globals.getNode("/systems/electrical/test-volts-dc");
var test_ac	= props.globals.getNode("/systems/electrical/test-volts-ac");
var bus_dc	= props.globals.getNode("/systems/electrical/bus-dc");
var bus_ac	= props.globals.getNode("/systems/electrical/bus-ac");

#var switch_panel	= props.globals.getNode("/controls/switches/panel-norm");
#var controls_panel	= props.globals.getNode("/controls/lighting/panel-norm");
#var controls_flaps	= props.globals.getNode("/controls/flight/flaps");
#var controls_gear	= props.globals.getNode("/gear").getChildren("gear");	# Yeah, I know it's not a 'control'
#var controls_lighting	= props.globals.getNode("/controls/lighting");
#var controls_switches	= props.globals.getNode("/controls/switches");



#
# Primary electrical system support:
#

var update_generators = func {
  for(var i=0; i<size(engines); i+=1) {
	if (i<NUM_ENGINES) {
		if (!engines[i].getNode("out-of-fuel").getValue() and sw_gen[i].getNode("position").getValue()) {
			feed_status[i] = 1;						# AC generator enabled
			feed_status[i+RECT_OFFSET] = 1;					# DC rectifier enabled
			#sources[i].getNode("on").setValue(1);
			#sources[i+RECT_OFFSET].getNode("on").setValue(1);
		} else {
			feed_status[i] = 0;
			feed_status[i+RECT_OFFSET] = 0;
			#sources[i].getNode("on").setValue(0);
			#sources[i+RECT_OFFSET].getNode("on").setValue(0);
		}
    	}
  }
}

var update_apu = func {
  if (apu_running.getValue()) {
    feed_status[feed["apu"]] = 1;
    sources[feed["apu"]].getNode("on").setValue(1);
  }
  else {
    feed_status[feed["apu"]] = 0;
    sources[feed["apu"]].getNode("on").setValue(0);
  }
}

var update_battery = func {
  if (sw_batt.getValue()) {
    feed_status[feed["batt"]] = 1;
    sources[feed["batt"]].getNode("on").setValue(1);
  }
  else {
    feed_status[feed["batt"]] = 0;
    sources[feed["batt"]].getNode("on").setValue(0);
  }
}
									# External power is available only if
									# aircraft is on the ground and stopped
var update_cart = func {
  if (sw_cart.getValue() and
      cart_wow.getValue() and
      gndspd.getValue() < 0.1) {
    feed_status[feed["cart"]] = 1;
    #sources[feed["cart"]].getNode("on").setValue(1);
  }
  else {
    feed_status[feed["cart"]] = 0;
    #sources[feed["cart"]].getNode("on").setValue(0);
  }
}


var update_bus = func {
  var volts_ac = 0;							# Assume no volts on bus
  var volts_dc = 0;							# Assume no volts on bus
  for(var i=0; i<size(feed_status); i+=1) {				# Check all possible feeds
    if (feed_status[i]) {						# If feed is on
      var source_volts = sources[i].getNode("volts").getValue();
      if (sources[i].getNode("flow").getValue() == "ac") {
        if (source_volts > volts_ac) {					# Volts takes on largest source value
          volts_ac = source_volts;
        }
      }
      else {
        if (source_volts > volts_dc) {					# Volts takes on largest source value
          volts_dc = source_volts;
        }
      }
    }
  }
  bus_dc.getNode("volts").setValue(volts_dc);				# Bus takes on largest source value
  bus_ac.getNode("volts").setValue(volts_ac);				# Bus takes on largest source value
}


									# Update the voltmeter on change of bus volts
var update_voltmeter = func {
  interpolate(test_dc,bus_dc.getNode("volts").getValue(),1.5);
  interpolate(test_ac,bus_ac.getNode("volts").getValue(),1.5);
}


									# Enable or cut power to various electrical stuff.
									# This is a quick-and-dirty way to do this--
									# Better to set up an extensible xml-driven system.
									# But I'm looking for instant-grat right now.
#var update_bus_outputs = func {
#  if (bus_dc.getNode("volts").getValue() > MIN_VOLTS_DC) {
    #controls_panel.setValue(switch_panel.getValue());
    #controls_lighting.getNode("lamp-flaps").setValue(controls_flaps.getValue());
    #controls_lighting.getNode("lamp-gear-left").setValue(controls_gear[1].getNode("position-norm").getValue());
    #controls_lighting.getNode("lamp-gear-right").setValue(controls_gear[2].getNode("position-norm").getValue());
    #controls_lighting.getNode("beacon").setValue(controls_switches.getNode("beacon").getValue());
    #controls_lighting.getNode("tail").setValue(controls_switches.getNode("tail").getValue());
    #controls_lighting.getNode("nav").setValue(controls_switches.getNode("nav").getValue());
    #controls_lighting.getNode("landing-left").setValue(controls_switches.getNode("landing-left").getValue());
    #controls_lighting.getNode("landing-right").setValue(controls_switches.getNode("landing-right").getValue());
#  }
#  else {
    #controls_panel.setValue(0);
    #controls_lighting.getNode("lamp-flaps").setValue(0);
    #controls_lighting.getNode("lamp-gear-left").setValue(0);
    #controls_lighting.getNode("lamp-gear-right").setValue(0);
    #controls_lighting.getNode("beacon").setValue(0);
    #controls_lighting.getNode("tail").setValue(0);
    #controls_lighting.getNode("nav").setValue(0);
    #controls_lighting.getNode("landing-left").setValue(0);
    #controls_lighting.getNode("landing-right").setValue(0);
#  }
#}


									# The master bus update system
var update_electrical = func {
									# Feed updates:
  update_generators();
  #update_apu();
  feed_status[feed["apu"]] = apu_running.getValue();
  #update_battery();
  feed_status[feed["batt"]] = sw_batt.getValue();
  update_cart();
									# Bus updates
  update_bus();
  #update_bus_outputs();
  update_voltmeter();
  settimer(update_electrical,ELEC_UPDATE_PERIOD);			# Schedule next run
}


settimer(update_electrical, 2);						# Give a few seconds for vars to initialize
