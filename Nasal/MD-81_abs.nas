# MD-81
#
# Automatic Brake System support routines
#
# Gary Neely aka 'Buckaroo'
#


var ABS_DELTA		= 0.5;						# Delta in secs for full brake effect
var ABS_UPDATE		= 1;						# How often we monitor the deployed ABS system
var ABS_MAX		= 1;						# Maximum braking force (true value unknown)
var ABS_MED		= 0.65;						# Medium braking force
var ABS_MIN		= 0.4;						# Minimum braking force
var ABS_DELAY_MIN	= 1;						# Short delay to engage brakes
var ABS_DELAY_MAX	= 3;						# Standard delay to engage brakes

var abs_sw_arm		= props.globals.getNode("/controls/autobrakes/ABS");
var abs_select		= props.globals.getNode("/controls/autobrakes/ABS-select");
var abs_armed		= props.globals.getNode("/systems/autobrakes/armed");
var abs_deployed	= props.globals.getNode("/systems/autobrakes/deployed");
var abs_throttle0	= props.globals.getNode("/controls/engines/engine[0]/throttle");
var abs_throttle1	= props.globals.getNode("/controls/engines/engine[1]/throttle");
var abs_wow		= props.globals.getNode("/gear/gear[0]/wow");
var abs_rollspeed	= props.globals.getNode("/gear/gear[0]/rollspeed-ms");
#var spoilers_master	# Defined in flightsurfaces
#var spoilers_ground	# Defined in flightsurfaces
#var flaps_pos		# Defined in flightsurfaces

var abs_decel		= 1;
var abs_listener	= 0;
var stage		= 1;


									# Manual braking:
									# Can't apply brakes if ABS in control
									# This is a re-definition of the default
									# controls.applyBrakes function
controls.applyBrakes = func(v, which = 0) {
  if (abs_deployed.getValue() or abs_armed.getValue() or (abs_select.getValue() != 1)) { return 0; }
  if (which <= 0) { interpolate("/controls/gear/brake-left", v, ABS_DELTA); }
  if (which >= 0) { interpolate("/controls/gear/brake-right", v, ABS_DELTA); }
}


									# Activate/deactive ABS:
									# Listener on /controls/flight/spoilers-master:
var abs_arm = func {
  if (abs_sw_arm.getValue() and !abs_armed.getValue()) {
    abs_armed.setValue(1);						# Arm the system and set up activation listener
    abs_listener = setlistener("/controls/flight/spoilers-master", abs_primary);
  }
  elsif (!abs_sw_arm.getValue() and abs_armed.getValue()) {		# Disarm system and remove activation listener
    abs_disarm();
  }
}


var abs_disarm = func {							# Disarm undeployed system and remove activation listener
  abs_armed.setValue(0);						# Get us out of armed mode
  abs_sw_arm.setValue(0);						# Switch off (the switch is magnetically released)
  removelistener(abs_listener);						# Kill the listener
}

									# Primary determination of activation is based
									# on deployment of ground spoilers
var abs_primary = func {
  if (spoilers_master.getValue() < 1) { return 0; }			# Only care if ground spoilers deployed
  if (abs_deployed.getValue()) { return 0; }				# Sanity check
  if (stage > 1) { return 0; }						# Make sure we don't repeatedly enter 2nd stage
  stage = 2;								# Set up for second stage
  abs_secondary();							# Move to secondary activation monitor
}


									# Secondary determination of activation requires
									# weight on nose gear.
									# If ground spoilers have deployed, wait and see
									# if nose gear touches, then deploy brakes
var abs_secondary = func {
  if (spoilers_master.getValue() < 1) {					# If ground spoilers retracted,
    stage = 1;								# Reset activation stage
    abs_disarm();							# set auto-disarm and exit loop
    return 0;
  }
  if (!abs_wow.getValue()) {						# Nose gear not yet on ground, try again
    settimer(abs_secondary, ABS_UPDATE);
    return 0;
  }
									# ABS activation also requires:
									#   flaps in TakeOff position
									#   throttles retarded
  # if (flaps_pos.getValue() > 0 and					# This is for TO mode, not correctly implemented yet
  if (abs_throttle0.getValue() > 0 or
      abs_throttle1.getValue() > 0) {					# If conditions not met, end looping
    stage = 1;								# Reset activation stage
    abs_disarm();							# and set auto-disarm
    return 0;
  }

									# Conditions met, deploy brakes
  abs_deployed.setValue(1);
  stage = 1;								# Reset activation stage
  abs_decel = ABS_MAX;							# Default to max decelleration
  if (abs_select.getValue() == 0 or abs_select.getValue() == 4) {	# ABS TakeOff or MAX setting
    settimer(abs_deploy,ABS_DELAY_MIN);
  }
  elsif (abs_select.getValue() == 2) {					# ABS MIN setting
    abs_decel = ABS_MIN;
    settimer(abs_deploy,ABS_DELAY_MAX);
  }
  else {								# ABS MED setting
    abs_decel = ABS_MED;
    settimer(abs_deploy,ABS_DELAY_MAX);
  }
}


var abs_deploy = func {
  #print("Brakes deploying, decel: ", abs_decel);
  interpolate("/controls/gear/brake-left", abs_decel, ABS_DELTA);
  interpolate("/controls/gear/brake-right", abs_decel, ABS_DELTA);
  abs_deployed_loop();
}

									# Watch for conditions to disable deployed brakes
var abs_deployed_loop = func {
  if (!abs_armed.getValue())		{ if (abs_deployed.getValue()) { abs_off(); } return 0; }
  if (abs_select.getValue() == 1)	{ if (abs_deployed.getValue()) { abs_off(); } return 0; }
  if (!spoilers_ground.getValue())	{ if (abs_deployed.getValue()) { abs_off(); } return 0; }
  if (abs_throttle0.getValue() > 0)	{ if (abs_deployed.getValue()) { abs_off(); } return 0; }
  if (abs_throttle1.getValue() > 0)	{ if (abs_deployed.getValue()) { abs_off(); } return 0; }
  if (abs_wow.getValue() and (abs_rollspeed.getValue() < 0.01))
					{ if (abs_deployed.getValue()) { abs_off(); } return 0; }

  settimer(abs_deployed_loop, ABS_UPDATE);
}


									# Disable deployed brakes
var abs_off = func {
  interpolate("/controls/gear/brake-left", 0, ABS_DELTA);
  interpolate("/controls/gear/brake-right", 0, ABS_DELTA);
  abs_deployed.setValue(0);
  abs_armed.setValue(0);						# Get us out of armed mode
  abs_sw_arm.setValue(0);						# Switch off (the switch is magnetically released)
}
