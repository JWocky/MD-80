# MD-81
#
# APU support routines
#
# Gary Neely aka 'Buckaroo'
#
# Basics:
#
# APU can contribute electrical power immediately after start-up.
# bleed air - set switch to enable, required for engine start. auto-off upon apu shutdown
# warmup - 60 secs after start before air is provided, regardless of air switch
# RPM - normal is 95-105%. Constant RPM regardless of load.
# EGT - normal temp is ~350 Cdeg, rises when air enabled, maybe 450?
# battery should be enabled (windmill starting possible)
# fuel - from right tank. requires DC start pump or any right or center boost pump;
# can take from left boost pump if fuel X feed is on (x-feed is open). At least one
# main boost pump should be on.
# fuel usage - 300-350 pounds per hour, or 70-80 kg/hr w/o air, 140-150 kg/hr w air
#



var APU_UPDATE_PERIOD	= 5;						# A periodic status update in secs
var APU_SW_RESET_PERIOD	= 3;						# Start->Run in secs
var RPM_NORM		= 100;						# 100%
var EGT_NORM		= 350;						# Normal running EGT
var EGT_AIR		= 425;						# EGT when contributing pneumatic air
var RPM_TRANS		= 7;						# Transition time to full RPM in secs
var EGT_TRANS		= 30;						# Transition time to norm EGT in secs
var EGT2_TRANS		= 5;						# Transition time from norm to air EGT in secs
var APU_WARMUP		= 60; 						# Time required to warmup APU before air can be used
#var MIN_VOLTS_DC	# Defined in electrical system

									# Other property handles:
var apu_running		= props.globals.getNode("/systems/apu/running");
var apu_air		= props.globals.getNode("/systems/apu/air");
var apu_state		= props.globals.getNode("/systems/apu/state");
var apu_oof		= props.globals.getNode("/systems/apu/out-of-fuel");
var apu_rpm		= props.globals.getNode("/systems/apu/rpm");
var apu_egt		= props.globals.getNode("/systems/apu/egt");
var apu_sw_master	= props.globals.getNode("/controls/switches/apu-master");
var apu_sw_air		= props.globals.getNode("/controls/switches/apu-air");
#var bus_dc		# Defined in electrical system
#var fuelpress		# Defined in fuel system

var apu_egt_actual = EGT_NORM;
var air_loop       = 0;							# Makes sure only 1 instance of  air monitor is running


var apu_switch = func {							# Positions: 0 off, 1 run, 2 start
  if (apu_sw_master.getValue()==0 and apu_running.getValue()) {
    apu_shutdown();
    return 0;
  }
  if (apu_sw_master.getValue()==1) {
    return 0;
  }
  if (apu_sw_master.getValue()==2) {
    apu_start();
  }
}


var apu_switch_reset = func {
  apu_sw_master.setValue(1);
}


var apu_air_switch = func {						# EGT is higher if APU is used to feed air to
  if (apu_sw_air.getValue() and !apu_air.getValue() and !air_loop) {	# pneu bus; fire up the air monitoring loop
    air_loop = 1;
    apu_air_loop();
  }
}

									# Starting requires good DC volts,
									# pressure on the right fuel system,
									# and fuel to the APU (not yet simulated)
var apu_start = func {
  if (bus_dc.getNode("volts").getValue() >= MIN_VOLTS_DC and fuelpress[1] and !apu_oof.getValue())
    {
    apu_running.setValue(1);						# Set running
    settimer(apu_switch_reset, APU_SW_RESET_PERIOD);			# Reset to run position after a delay
									# RPM: interpolate current to 100% in (100-current)/100 * 7 secs
    interpolate(apu_rpm, RPM_NORM, (RPM_NORM - apu_rpm.getValue())/RPM_NORM * RPM_TRANS);
									# EGT: interpolate current to 350 in (350-current)/350 * 7 secs
    interpolate(apu_egt, apu_egt_actual, (apu_egt_actual - apu_egt.getValue())/apu_egt_actual * EGT_TRANS);
									# Warmup period
    interpolate(apu_state, 1, (1 - apu_state.getValue()) * APU_WARMUP);
    }
}


var apu_shutdown = func {
  apu_running.setValue(0);
  interpolate(apu_rpm, 0, apu_rpm.getValue()/RPM_NORM * RPM_TRANS);
  interpolate(apu_egt, 0, apu_egt.getValue()/EGT_NORM * EGT_TRANS);
  interpolate(apu_state, 0, apu_state.getValue() * APU_WARMUP);
}


									# Used to monitor air actions
var apu_air_loop = func {
  var air = apu_sw_air.getValue();
  var warmup = apu_state.getValue();
  var keep_looping = 1;

  if (air and warmup < 1) {						# Air on but system not yet warmed up
    apu_air.setValue(0);
  }
  elsif (air and warmup==1 and !apu_air.getValue()) {			# Air on and system ready and air not already enabled
    apu_air.setValue(1);
    apu_egt_actual = EGT_AIR;
    interpolate(apu_egt, apu_egt_actual, (apu_egt_actual - apu_egt.getValue())/apu_egt_actual * (EGT_TRANS+EGT2_TRANS));
  }
  elsif (!air and apu_egt_actual > EGT_NORM) {				# Air off but system still in air producing state
    keep_looping = 0;
    apu_air.setValue(0);
    apu_egt_actual = EGT_NORM;
    interpolate(apu_egt, apu_egt_actual, (apu_egt.getValue() - EGT_NORM)/(EGT_NORM + EGT_AIR) * (EGT_TRANS+EGT2_TRANS));
  }
  elsif (!air) {							# Air off before warm-up finished
    keep_looping = 0;
    apu_air.setValue(0);
  }

  if (keep_looping)		{ settimer(apu_air_loop, APU_UPDATE_PERIOD); }
  else				{ air_loop = 0; }
}

