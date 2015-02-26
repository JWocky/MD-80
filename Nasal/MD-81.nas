# McDonnell Douglas MD-81
#
# Initialization
#
# Gary Neely aka 'Buckaroo'
#

aircraft.livery.init("Aircraft/MD-80/Models/Liveries");

								# Set up screen message windows
var md83_screenmssg	= screen.window.new(nil, -150, 2, 5);
var md83_screenmssg2	= screen.window.new(nil, -180, 2, 5);

								# Lighting setup

								# Install beacon timer and controller
beacon_switch = props.globals.getNode("/controls/lighting/beacon", 1);
beacon_switch.setBoolValue(0);
aircraft.light.new("/sim/model/lighting/beacon", [0.2, 2], beacon_switch);
								# Pass beacon timer over MP (aliasing the timer value
								# doesn't seem to work, so a listener is used)
								# Use MP var float[3]
var MD83_BeaconState	= props.globals.getNode("sim/model/lighting/beacon/state[0]", 1);
var MD83_MPBeaconState	= props.globals.getNode("/sim/multiplay/generic/float[3]", 1);
setlistener(MD83_BeaconState, func {
  if (MD83_BeaconState.getBoolValue())	{ MD83_MPBeaconState.setValue(1) }
  else					{ MD83_MPBeaconState.setValue(0) }
});

var controls_nav	= props.globals.getNode("/controls/lighting/nav");
var controls_wingtipaft	= props.globals.getNode("/controls/lighting/wingtipaft");
var controls_beacon	= props.globals.getNode("/controls/lighting/beacon");
var lights_nav_toggle = func {
  md83_screenmssg.fg = [1, 1, 1, 1];
  if (controls_nav.getValue()) {
    controls_nav.setValue(0);
    controls_wingtipaft.setValue(0);
    md83_screenmssg.write("Nav lights off.");
  }
  else {
    controls_nav.setValue(1);
    controls_wingtipaft.setValue(1);
    md83_screenmssg.write("Nav lights on.");
  }
}
var lights_beacon_toggle = func {
  md83_screenmssg.fg = [1, 1, 1, 1];
  if (controls_beacon.getValue()) {
    controls_beacon.setBoolValue(0);
    md83_screenmssg.write("Beacon lights off.");
  }
  else {
    controls_beacon.setBoolValue(1);
    md83_screenmssg.write("Beacon lights on.");
  }
}


								# AP/AT stuff: (will live elsewhere eventually)

autothrottle		= props.globals.getNode("/autopilot/locks/speed");
autothrottle_mode	= props.globals.getNode("/autopilot/locks/at-mode");
at_switch		= props.globals.getNode("/controls/switches/at");
var autothrottle_toggle = func {
  if (!autothrottle.getValue())	{
    at_switch.setValue(1);					# Set switch to on position
    if (autothrottle_mode.getValue() == 0) {			# AT mode 0 is speed
      autothrottle.setValue("speed-with-throttle");
    }
    else {							# At mode 1 is mach
      autothrottle.setValue("mach-with-throttle");
    }
  }
  else {
    autothrottle.setValue("");
    at_switch.setValue(0);
  }
}


								# Establish which settings are saved on exit
var MD83_Savedata = func {
  aircraft.data.add("/controls/lighting/digital-norm");		# Numeric readouts lighting
  aircraft.data.add("/controls/lighting/pfd-norm");		# Primary flight display lighting
  aircraft.data.add("/controls/lighting/nd-norm");		# Navigational display lighting
  aircraft.data.add("/controls/lighting/panel-norm");		# Standard instrument lighting
  aircraft.data.add("/sim/instrument-options/hsi/show-rudder");	# Rudder and throttle display on HSI
}



								# Initialization:

setlistener("/sim/signals/fdm-initialized", func {
								# Start the fuel system. The MD-81 uses a customized
								# fuel routine to avoid the default cross-feed situation.
  FuelInit();							# See MD-81_fuel.nas
								# Start the custom flight surface system. The MD-81 uses
								# this to handle spoiler operations and tabbed control
								# surface simulation.
  FlightSurfaceInit();						# See MD-81_flightsurfaces.nas
  PneumaticsInit();						# See MD-81_pneumatics.nas
  InstrumentationInit();					# See MD-81_instrumentation_drivers.nas
  MD83_Savedata();
});


