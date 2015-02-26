# McDonnell Douglas MD-81
#
# Custom Flight Surface Operations
#
# Gary Neely aka 'Buckaroo'
#
# Elevator operations:
#
# The MD-80 series elevators are not typically directly controlled, but are 'flown' into position by
# operation of smaller control tabs along the trailing edge. These tabs are directly linked to the
# cockpit flight controls. As an effect, at low ground speeds there is not enough airflow for the
# elevators to be fully controlled. At rest, the elevators are free to move with the wind.
#
# To simulate this, elevator throw is reduced below a certain speed (currently 50 kts), and goes away
# altogether below a minimum speed (currently 20 kts). Currently below the minimum speed elevator position
# is neutralized, but in reality they take on odd positions, often up-elevator due to wind and balance
# considerations.
#
# Aileron operations:
#
# Like elevators, ailerons are also tab-controlled and have a similar animated functionality.
#
# Rudder operations:
#
# Rudders can be tab-controlled but are normally hydraulically actuated. There are no special
# rudder functions here.
#
# Slat operations:
#
# Slats are currently slaved to flap position based on my current understanding.
# Mid-sealed: flaps to 13%, Extended: flaps 15-40%
#
# Spoiler operations:
#
# 3 sets of symmetrical spoilers
# flight spoilers (2 outboard treated as a single unit in the model)
# ground spoilers (1 inboard)
#
# General spoiler rules for MD-80 series:
#
# Flight spoilers perform aileron-assist when the aileron action exceeds 5 degrees deflection.
# Spoilers on the descending wing are activated.
# Spoilers deploy up to 30 degrees in flight mode.
# If spoilers are deployed, aileron-assist activity retracts spoilers on ascending side.
# In ground mode, spoilers deploy to a maximum of 60 degrees.
# Ground spoilers deploy only when there is weight on MLG (or NLG strut compression detected, not currently modeled)
# Speedbrake mode is locked-out when flaps are moved to 8 degrees or more (>11 degrees in the model)
# Lock-out is deactivated if flaps are retracted under 8 degrees or ground deployment conditions are met.
# Ground braking may be armed, in which case deployment is automatic when conditions are met.
#
# Currently the FDM has only one wing defined with one spoiler. Until I work out how to do separate wing
# sections in the FDM, this limitation required me to come up with a scheme to differentiate effects of
# the MD-81 having essentially two sets of spoilers. I do this by basing controls off a 'master' cockpit
# setting, and then dynamically modifying the actual 'spoilers' control based on the rules above. What
# this means is that spoiler effects are fairly light in the air, but massive on the ground.
#


var UPDATE_PERIOD	= 0;					# How often to update main loop in seconds (0 = framerate)
var ENV_UPDATE_PERIOD	= 120;					# How often to update environment factors in seconds
var EL_SEEK_TIME	= 30;					# See below. Make sure this is less than ENV_UPDATE_PERIOD
var MASTER_DELTA	= 0.5;					# How much we can inc/dec master spoiler control
var MASTER_MAX		= 1;					# Maximum we can inc/dec master spoiler control
var SP_FACTOR		= 0.666;				# Factor to convert master value to true spoiler value
var SP_BIAS		= 0.333;				# Ground mode spoiler bias
								# 0.5 yields 2 positions
var AIL_NULL_RANGE	= 0.25;					# Aileron throw range for which there is no spoiler activity
								# Assuming 20 degrees max down, 0.25 yields a 5 degree range
								# for which spoilers remain retracted. This is correct for MD.
var SP_TRANSIT_TIME	= 1;					# In seconds
var MAX_FLAPS		= 0.275;				# Maximum normalized flaps that still allows spoiler deployment
								# True max should be 0.2 (8 deg), I allow up to 11 deg as all
								# real flap positions are not simulated.
var FULL_EFFECT_SPD	= 50;					# Above this speed, elevators fully respond to control tabs
var MIN_EFFECT_SPD	= 20;					# Below this speed, elevators do not respond to control tabs
var EFFECT_DIFF		= 30;					# full_effect_spd - min_effect_spd, so we don't calculate it every iteration


var altitude_agl	= props.globals.getNode("/position/altitude-agl-ft");
var airspeed		= props.globals.getNode("/velocities/airspeed-kt");
var heading		= props.globals.getNode("/orientation/heading-deg");
var wind_hdg		= props.globals.getNode("/environment/wind-from-heading-deg");
var wind_spd		= props.globals.getNode("/environment/wind-speed-kt");

var el_pos_adj		= props.globals.getNode("/controls/flight/el-pos-adj");
var el_pos		= props.globals.getNode("/surface-positions/elevator-pos-norm",1);
var el_pos_ani		= props.globals.getNode("/surface-positions/elevator-pos-ani-norm",1);
var ail_pos_left	= props.globals.getNode("/surface-positions/left-aileron-pos-norm",1);
var ail_pos_right	= props.globals.getNode("/surface-positions/right-aileron-pos-norm",1);
var ail_pos_ani_left	= props.globals.getNode("/surface-positions/left-aileron-pos-ani-norm",1);
var ail_pos_ani_right	= props.globals.getNode("/surface-positions/right-aileron-pos-ani-norm",1);

var spoilers_pos	= props.globals.getNode("/surface-positions/spoiler-pos-norm");
var flaps_pos		= props.globals.getNode("/surface-positions/flap-pos-norm");
var wow			= props.globals.getNode("/gear/gear[1]/wow");
var spoilers_master	= props.globals.getNode("/controls/flight/spoilers-master");
var spoilers		= props.globals.getNode("/controls/flight/spoilers");
var spoilers_auto	= props.globals.getNode("/controls/flight/spoilers-auto");
var spoilers_auto_ani	= props.globals.getNode("/controls/flight/spoilers-auto-ani");
var spoilers_prearm	= props.globals.getNode("/controls/flight/spoilers-prearm");
var spoilers_lockout	= props.globals.getNode("/controls/flight/spoilers-lockout");
var spoilers_ground	= props.globals.getNode("/controls/flight/spoilers-pos-norm-ground");
var spoilers_flight	= props.globals.getNode("/controls/flight/spoilers-pos-norm-flight");
var spoilers_left	= props.globals.getNode("/controls/flight/spoilers-pos-norm-left");
var spoilers_right	= props.globals.getNode("/controls/flight/spoilers-pos-norm-right");

var sp_ground_target	= 0;
var sp_flight_target	= 0;

								# This functions updates environment-related vars.
								# Mainly this controls the at-rest pitch of the elevator
								# due to wind and heading forces.
var env_effects = func {
  if (airspeed.getValue() > 150) { return 0 };			# Don't bother if it looks like we're flying for a while
  
  var wind = 0;							# This will give us a relative for-aft wind position
  if (wind_hdg.getValue() > heading.getValue()) {
    wind = wind_hdg.getValue() - heading.getValue();
  }
  else {
    wind = 360 - (heading.getValue() - wind_hdg.getValue());
  }
  if (wind > 180) {						# Gives us the degrees off the bow, we don't care about
    wind = 360 - wind;						# port or starboard
  }
  
  var el_pos = 0;						# Position elevator will seek over time
  if (wind < 112.5) {						# If relative wind is on the beam or forward
    el_pos = 0;							# elevator seeks neutral position
  }
  else {
    var wind_pos_factor = (wind - 112.5) / 67.5;		# Wind has a greater effect as it comes astern
    var wind_spd_factor = 0;
    if (wind_spd.getValue() >= 15) {				# Wind effects top out at 15+ knots
      wind_spd_factor = 1;
    }
    else {
      wind_spd_factor = wind_spd.getValue() / 15;		# Otherwise wind effects are normalized within range
    }
    el_pos = wind_pos_factor * wind_spd_factor * -1;		# Elevator position most deflected at 15 knots astern
  }
  interpolate(el_pos_adj, el_pos, EL_SEEK_TIME);		# Elevator will seek this new position over time

  settimer(env_effects, ENV_UPDATE_PERIOD);
}

								# These functions should be called by the controllers
								# that are set to extend/retract spoilers
var spoiler_extend = func {
  var master = spoilers_master.getValue();			# Master cockpit spoiler control
  if (!wow.getValue() and master == MASTER_DELTA) { return 0; }	# Can't extend beyond half way (30 degrees) in flight
								# Check for max flaps limit
  if (!wow.getValue() and (flaps_pos.getValue() > MAX_FLAPS)) { return 0; }
  if (master >= MASTER_MAX) { return 0; }
  master = master + MASTER_DELTA;
  spoilers_master.setValue(master);
}
var spoiler_retract = func {
  var master = spoilers_master.getValue();			# Master cockpit spoiler control
  if (master <= 0) { return 0; }
  master = master - MASTER_DELTA;
  spoilers_master.setValue(master);
}

								# These functions set the ground auto-deploment of
								# spoilers
var spoiler_arm = func {
  if (wow.getValue()) {						# Pre-arming spoilers on the ground is allowable and
    spoilers_prearm.setBoolValue(1);				# part of flight procedures
  }
  else {							# In-flight arming of ground spoilers
    spoilers_auto.setBoolValue(1);
  }
  spoilers_auto_ani.setBoolValue(1);				# For cockpit speedbrake lever animation
  md83_screenmssg.fg = [1, 1, 1, 1];
  md83_screenmssg.write("Ground spoilers armed.");
}
var spoiler_disarm = func {
  spoilers_auto.setBoolValue(0);
  spoilers_auto_ani.setBoolValue(0);
  md83_screenmssg.fg = [1, 1, 1, 1];
  md83_screenmssg.write("Ground spoilers disarmed.");
}


								# Slats are currently auto-engaged in a manner that
								# approximates the real automatic operation:
								#
								# Mid-sealed:	flaps to 13%
								# Extended:	flaps 15-40%

var pos_flaps	= props.globals.getNode("/controls/flight/flaps");
var pos_slats	= props.globals.getNode("/controls/flight/slats");

setlistener("/controls/flight/flaps", func {
  var flaps = pos_flaps.getValue();
  if (flaps >= 0.375)	{ pos_slats.setValue(1.0); return 0; }
  if (flaps > 0)	{ pos_slats.setValue(0.5); return 0; }
  pos_slats.setValue(0);
});


								# Primary flight surface loop
								# Since this is likely run every frame for best effect,
								# it's best to minimize what's done in this loop.
var flightsurface_loop = func {

								# Elevator & aileron position animation control:
  var as = airspeed.getValue();
								# Surface pos depends on indicated airspeed
  if (as > FULL_EFFECT_SPD) {					# Above full_effect_spd, elpos_ani = elpos
    el_pos_ani.setValue(el_pos.getValue());
    ail_pos_ani_left.setValue(ail_pos_left.getValue());
    ail_pos_ani_right.setValue(ail_pos_right.getValue());
  }
  elsif (as < MIN_EFFECT_SPD) {					# Below min_effect_spd, surface position is neutral
    el_pos_ani.setValue(el_pos_adj.getValue());			# This is a temporary solution, see notes
    ail_pos_ani_left.setValue(0);
    ail_pos_ani_right.setValue(0);
  }
  else {							# Normalize difference between airspeed and min
								# effect speed, and factor surface position by
								# that value to get animated position
    var factor = (as - MIN_EFFECT_SPD) / EFFECT_DIFF;
    el_pos_ani.setValue(el_pos.getValue() * factor);
    ail_pos_ani_left.setValue(ail_pos_left.getValue() * factor);
    ail_pos_ani_right.setValue(ail_pos_right.getValue() * factor);
  }



								# Check for auto-spoiler deployment:
  if (spoilers_auto.getValue()) {
    if (wow.getValue()) {
      spoilers_master.setValue(MASTER_MAX);			# Fully deploy spoilers
      spoilers_auto.setBoolValue(0);
      spoilers_auto_ani.setBoolValue(0);
    }
  }
  elsif (spoilers_prearm.getValue()) {				# If ground pre-arm set and altitude > 50 ft
    if (altitude_agl.getValue() > 50) {
      spoilers_auto.setBoolValue(1);				# Enable auto-spoilers
      spoilers_prearm.setBoolValue(0);				# Turn off pre-arm condition
    }
  }
								# Check operation mode (flight/ground)
  var master = spoilers_master.getValue();
								# In flight mode, spoiler effectiveness is reduced because only the
								# flight spoilers are deployed, about 2/3 of the spoiler total. In
								# ground mode, both flight and ground spoilers are deployed.
  if (wow.getValue() and master > 0) {				# In ground mode, spoilers can reach max value
    spoilers.setValue((master * SP_FACTOR) + SP_BIAS);		# Set spoiler control for FDM
  }
  else {							# Flight mode, spoilers factored to 2/3 effectiveness
    spoilers.setValue(master * SP_FACTOR);			# Set spoiler control for FDM
  }


								# Aileron support functions:
  var ailL = ail_pos_left.getValue();
  var ailR = ail_pos_right.getValue();
  var spL = ailR-AIL_NULL_RANGE;				# Left spoiler based on right aileron throw
  if (spL < 0) { spL = 0; }					# In null range, set throw to 0
  else {
    spL = spL / (1-AIL_NULL_RANGE);				# Normalize throw
    spL = spL / 2;						# Limits flight mode to 50% spoiler range
  }
  var spR = ailL-AIL_NULL_RANGE;				# Right spoiler based on left aileron throw
  if (spR < 0) { spR = 0; }					# In null range, set throw to 0
  else {
    spR = spR / (1-AIL_NULL_RANGE);				# Normalize throw
    spR = spR / 2;						# Limits flight mode to 50% spoiler range
  }

								# Flight spoiler operation:
  if (master != sp_flight_target) {				# Start interpolation if not already under way
    interpolate(spoilers_flight, master, SP_TRANSIT_TIME);
    sp_flight_target = master;
  }

								# Ground spoiler operation:
  if (master < spoilers_ground.getValue()) {			# Always OK to retract ground spoilers
    if (master != sp_ground_target) {				# Start interpolation if not already under way
      interpolate(spoilers_ground, master, SP_TRANSIT_TIME);
      sp_ground_target = master;
    }
  }
  elsif (wow.getValue() and master > 0) {			# Ground spoilers can deploy only with weight-on-wheels
    if (master != sp_ground_target) {				# Start interpolation if not already under way
      interpolate(spoilers_ground, master, SP_TRANSIT_TIME);
      sp_ground_target = master;
    }
  }

  if (spoilers_flight.getValue() > 0) {				# Spoilers deployed, so aileron-assist reduces spoilers on
    var sp_flight = spoilers_flight.getValue();			# ascending side
    spR = sp_flight - spR;
    spL = sp_flight - spL;
    spoilers_right.setValue(spL);				# Set throw to same-side spoiler
    spoilers_left.setValue(spR);				# Set throw to same-side spoiler
  }
  else {							# Spoilers not deployed, so add spoiler action to descending side
    spoilers_right.setValue(spR);				# Set throw to opposite spoiler
    spoilers_left.setValue(spL);				# Set throw to opposite spoiler
  }

  settimer(flightsurface_loop, UPDATE_PERIOD);
}


var FlightSurfaceInit = func {

  settimer(env_effects, 2);
  settimer(flightsurface_loop, 3);				# Delay startup a bit to allow things to initialize
}

