# McDonnell Douglas MD-81
#
# Fuel Update routines
# Essentially a modified version of standard fuel.nas that has engines draw fuel from array-sequenced tanks.
# Engine[n] draws from tank[n] and only tank[n]. The center tank [2] is used only if both center boost pumps are
# on. In this case, both engines draw from the center tank, because the center tank pumps are in series, whereas
# the main wing pumps are in parallel, therefore the center will feed before the others.
#
# APU consumes fuel from right tank:
#   no air: 176 lbs/hr,	0.49 lbs/sec, 0.0147 lbs/0.3 secs
#   air on: 330	lbs/hr, 0.0917 lbs/sec, 0.0275 lbs/0.3 secs
#
# Gary Neely aka 'Buckaroo'
#
# 04/11/2012 - Fixed Fuel consumption issue caused by change in core fuel routines in FG 2.4.



# Properties under /consumables/fuel/tank[n]:
# + level-gal_us    - Current fuel load.  Can be set by user code.
# + level-lbs       - OUTPUT ONLY property, do not try to set
# + selected        - boolean indicating tank selection.
# + density-ppg     - Fuel density, in lbs/gallon.
# + capacity-gal_us - Tank capacity
#
# Properties under /engines/engine[n]:
# + fuel-consumed-lbs - Output from the FDM, zeroed by this script
# + out-of-fuel       - boolean, set by this code.



var UPDATE_PERIOD	= 0.3;
var PUMPS_UPDATE	= 3;
var PPG			= 6.72;						# Standard JetA density
var MIN_VOLTS_AC	= 115;						# Typical minimum voltage level for generic equipment
var MIN_VOLTS_DC	= 25;						# Typical minimum voltage level for generic equipment
var LBS_APU_NOAIR	= 0.0073; #0.0147;				# lbs consumed per update period
var LBS_APU_AIR		= 0.01375; #0.0275;				# lbs consumed per update period if air on
									# Above APU values halved due to update period
									# evidently running twice as fast as expected

var tank_list = [];							# Raw tank list
var tanks = [];								# Qualified tank list
var engines = [];
var fuel_freeze = nil;
var total_gals = nil;
var total_lbs = nil;
var total_norm = nil;

var cutoffs		= props.globals.getNode("/controls/engines").getChildren("engine");
var lockout_cutoffs	= props.globals.getNode("/controls/fuel/lockout-cutoffs");
var xfeed		= props.globals.getNode("/controls/fuel/xfeed");
var sw_pumpLaft		= props.globals.getNode("/controls/switches/pumpLaft");
var sw_pumpLfwd		= props.globals.getNode("/controls/switches/pumpLfwd");
var sw_pumpRaft		= props.globals.getNode("/controls/switches/pumpRaft");
var sw_pumpRfwd		= props.globals.getNode("/controls/switches/pumpRfwd");
var sw_pumpCaft		= props.globals.getNode("/controls/switches/pumpCaft");
var sw_pumpCfwd		= props.globals.getNode("/controls/switches/pumpCfwd");
var sw_startpump	= props.globals.getNode("/controls/switches/start-pump");
var sw_ign		= props.globals.getNode("/controls/switches/eng-ign");
var bus_dc		= props.globals.getNode("/systems/electrical/bus-dc");
var bus_ac		= props.globals.getNode("/systems/electrical/bus-ac");
var apu_running		= props.globals.getNode("/systems/apu/running");
var apu_air		= props.globals.getNode("/systems/apu/air");
var fuel_press_L	= props.globals.getNode("/systems/fuel/tank[0]/fuel-press");
var fuel_press_R	= props.globals.getNode("/systems/fuel/tank[1]/fuel-press");

var fuelpress		= [0,0,0,0,0];



									# Fuel pump monitor
									# A forward and/or aft pump is required for
									# each tank. For the right tank, the start pump
									# may also serve, but it should not run for
									# long periods.
									# Note that the center tank requires both pumps on to
									# ensure proper feeding ahead of mains.
var pumps_loop = func {
  var volts_ac = 0;
  var volts_dc = 0;
  if (bus_ac.getNode("volts").getValue() >= MIN_VOLTS_AC) { volts_ac = 1; }
  if (bus_dc.getNode("volts").getValue() >= MIN_VOLTS_DC) { volts_dc = 1; }

  if (sw_pumpCaft.getValue() and sw_pumpCfwd.getValue() and volts_ac and tank_list[2].getChild("level-gal_us").getValue()) {
         fuelpress[2] = 1; }						# Good boost pressure on center tank
  else { fuelpress[2] = 0; }

  if ((sw_pumpCaft.getValue() or sw_pumpCfwd.getValue()) or
     ((sw_pumpLaft.getValue() or sw_pumpLfwd.getValue()) and volts_ac and tank_list[0].getChild("level-gal_us").getValue())) {
         fuelpress[0] = 1;						# Good boost pressure on left tank
  }
  else { fuelpress[0] = 0; }

  if ((sw_pumpCaft.getValue() or sw_pumpCfwd.getValue()) or
     ((sw_pumpRaft.getValue() or sw_pumpRfwd.getValue()) and volts_ac and tank_list[1].getChild("level-gal_us").getValue()) or
     (sw_startpump.getValue() and volts_dc)) {
         fuelpress[1] = 1; }						# Good boost pressure on right tank
  else { fuelpress[1] = 0; }

  fuel_press_L.setValue(fuelpress[0]);
  fuel_press_R.setValue(fuelpress[1]);

  settimer(pumps_loop,PUMPS_UPDATE);					# Schedule next run
}


									# Toggle Fuel Cutoffs
var cutoff_toggle = func(i) {
  if (lockout_cutoffs.getValue()) { return 0; }				# Check for lockout
  if (cutoffs[i].getNode("cutoff").getValue()) {
    sw_ign.setValue(1);							# Igniter auto-engaged by opening a valve
    cutoffs[i].getNode("cutoff").setBoolValue(0);
  }
  else {
    cutoffs[i].getNode("cutoff").setBoolValue(1);
  }
}



var fuel_update = func {
  if (fuel_freeze) { return; }
									# Subtract consumed fuel from tanks, iterating over engines
									# Get initial fuel lbs:
  var tank_lbs = [
                 tank_list[0].getChild("level-lbs").getValue(),
                 tank_list[1].getChild("level-lbs").getValue(),
                 tank_list[2].getChild("level-lbs").getValue(),
                 tank_list[3].getChild("level-lbs").getValue(),
                 tank_list[4].getChild("level-lbs").getValue(),
                 ];
									# Engine consumption:
  var i = 0;
  foreach (var e; engines) {

									# Calculate fuel flow in lbs for instrumentation
    e.getNode("fuel-flow-pph").setDoubleValue(e.getNode("fuel-flow-gph").getValue()*PPG);

    if (cutoffs[i].getNode("cutoff").getValue()) {			# Engine fuel cutoff
      e.getNode("fuel-consumed-lbs").setDoubleValue(0);			# Reset engine's consumed fuel
      e.getNode("out-of-fuel").setBoolValue(1);				# Kill engine
      i += 1;								# Skip other fuel stuff, move on to next engine
      continue;
    }

    var consumed = e.getNode("fuel-consumed-lbs").getValue();		# Fuel consumed in lbs
    if (consumed) {							# Did engine consume any fuel?
      e.getNode("fuel-consumed-lbs").setDoubleValue(0);			# Reset engine's consumed fuel
      var satisfied = 0;						# Value of 1 indicates engine's fuel needs met

									# Center tank functionality:
#      var clbs = tank_lbs[2];
#      if (fuelpress[2] and clbs) {					# Center tank has fuel and is feeding
#        if (clbs > consumed) {						# Center tank meets fuel needs
#          clbs -= consumed;
#          consumed = 0;
#          satisfied = 1;
#        }
#        else {								# Center tank doesn't meet all fuel needs
#          consumed -= clbs;
#          clbs = 0;
#        }
#        tank_lbs[2] = clbs;						# Update center tank
#      }

									# Cross-feed functionality:
#      if (xfeed.getValue() and consumed) {				# xfeed enabled and fuel needs not yet met
#        if (fuelpress[0] == fuelpress[1]) {				# Both tanks have same fuel pressure
									# Draw fuel evenly from both tanks if possible
#          var empty = [0,0];
#          if (tank_lbs[0] < consumed) {					# Check if tank can feed
#            tank_lbs[1] = 0;						# Mark it empty
#            empty[0] = 1;
#          }
#          if (tank_lbs[1] < consumed) {					# Check if tank can feed
#            tank_lbs[1] = 0;						# Mark it empty
#            empty[1] = 1;
#          }
#          if (empty[0] and empty[1]) {					# Both tanks dry
#            consumed = 0;
#          }
#          elsif (empty[0] or empty[1]) {				# One tank is dry
#            var t = 0;
#            if (empty[0]) { t = 1; }					# Establish which tank is dry
#            tank_lbs[t] -= consumed;					# Feed from tank with fuel
#            consumed = 0;
#            satisfied = 1;
#          }
#          else {
#            var portion = consumed / 2;					# Reduce each tank by portion
#            tank_lbs[0] -= portion;
#            tank_lbs[1] -= portion;
#            consumed = 0;
#            satisfied = 1;
#          }
#        }
#        else {								# Unequal fuel pressure
									# Draw fuel from tank with greater pressure
#          var t = 0;
#          if (fuelpress[1] > fuelpress[0]) { t = 1; }			# Establish which tank has greater pressure
#          if (tank_lbs[t] >= consumed) {				# Can tank supply needs?
#            tank_lbs[t] -= consumed;					# Tank absorbs fuel needs
#            consumed = 0;
#            satisfied = 1;
#          }
#          else {							# Tank insufficient for needs
#            consumed -= tank_lbs[t];					# Reduce fuel needs by amount remaining in tank
#            tank_lbs[t] = 0;						# Empty tank
#          }
#        }
#      }

									# Standard feed functionality:
#      if (consumed) {							# Fuel needs not yet met, use standard engine i to tank i mapping
#        tank_lbs[i] -= consumed;					# Subtract consumed fuel from tank
#        if (tank_lbs[i] < 0) {						# Test for empty tank
#          tank_lbs[i] = 0;						# Mark it empty
#        }
#        else {
#          satisfied = 1;
#        }
#      }


#### changed for 5 tank configuration, quick and dirty

	if (i==0) {
		# first aux tank
		if (tank_lbs[3]>0) {
			tank_lbs[3]=tank_lbs[3]-consumed;
			satisfied=1;
		} else {
			# then center tank
			if (tank_lbs[2]>0) {
				tank_lbs[2]=tank_lbs[2]-consumed;
				satisfied=1;
			} else {
				# then wing tank
				if (tank_lbs[0]>0) {
					tank_lbs[0]=tank_lbs[0]-consumed;
					satisfied=1;
				}
			}
		}
	}

	if (i==1) {
		# first aux tank
		if (tank_lbs[4]>0) {
			tank_lbs[4]=tank_lbs[4]-consumed;
			satisfied=1;
		} else {
			# then center tank
			if (tank_lbs[2]>0) {
				tank_lbs[2]=tank_lbs[2]-consumed;
				satisfied=1;
			} else {
				# then wing tank
				if (tank_lbs[1]>0) {
					tank_lbs[1]=tank_lbs[1]-consumed;
					satisfied=1;
				}
			}
		}
	}
	

      if (!satisfied) {							# Were engine's fuel needs met?
        e.getNode("out-of-fuel").setBoolValue(1);			# If not, kill engine
      }

    }
    i += 1;								# Next engine
  }

									# APU consumption (always from right tank):
  if (apu_running.getValue()) {
    if (apu_air.getValue())	{ tank_lbs[2] -=  LBS_APU_AIR; }	# Air on
    else			{ tank_lbs[2] -=  LBS_APU_NOAIR; }	# No air
    if (tank_lbs[2] < 0) {						# Right tank dry?
      tank_lbs[2] = 0;
      apu_shutdown();
    }
  }

									# Update tank properties
  for(var j=0; j<=4; j+=1) {
    # tank_list[j].getChild("level-gal_us").setDoubleValue(tank_lbs[j]/PPG); # Deprecated by FG 2.4
    tank_list[j].getChild("level-lbs").setDoubleValue(tank_lbs[j]);
  }

									# Total fuel properties
  var lbs = 0;
  var gals = 0;
  var cap = 0;
  foreach (var t; tanks) {
    lbs += t.getNode("level-lbs").getValue();
    gals += t.getNode("level-gal_us").getValue();
    cap += t.getNode("capacity-gal_us").getValue();
  }
  total_lbs.setDoubleValue(lbs);
  total_gals.setDoubleValue(gals);
  total_norm.setDoubleValue(gals / cap);

  settimer(fuel_update, UPDATE_PERIOD);					# You go back, Jack, do it again...
}


var fuel_startup = func {
									# Deal with fuel menu select boxes
									# Note that these are not the cutoff valves;
									# A listener is used to re-enable oof status
									# if the user plays with the selection boxes

  var tank0_select	= props.globals.getNode("/consumables/fuel/tank[0]/selected");
  var tank1_select	= props.globals.getNode("/consumables/fuel/tank[1]/selected");
  var eng0_oof		= props.globals.getNode("/engines/engine[0]/out-of-fuel");
  var eng1_oof		= props.globals.getNode("/engines/engine[1]/out-of-fuel");
  
  setlistener(tank0_select, func {
    if (tank0_select.getValue()) { eng0_oof.setBoolValue(0); }
  });
  setlistener(tank1_select, func {
    if (tank1_select.getValue()) { eng1_oof.setBoolValue(0); }
  });

  pumps_loop();								# Start the pumps monitor
  fuel_update();							# Initiate fuel sequence
}


var init_double_prop = func(node, prop, val) {
  if (node.getNode(prop) != nil) {
    val = num(node.getNode(prop).getValue());
  }
  node.getNode(prop, 1).setDoubleValue(val);
}


var FuelInit = func {
  fuel.update = func{};							# Remove default fuel fuel system
  setlistener("/sim/freeze/fuel", func(n) { fuel_freeze = n.getBoolValue() }, 1);
  
  total_gals = props.globals.getNode("/consumables/fuel/total-fuel-gals", 1);
  total_lbs = props.globals.getNode("/consumables/fuel/total-fuel-lbs", 1);
  total_norm = props.globals.getNode("/consumables/fuel/total-fuel-norm", 1);
  
  tank_list = props.globals.getNode("/consumables/fuel",1).getChildren("tank");
  
  engines = props.globals.getNode("engines", 1).getChildren("engine");
  foreach (var e; engines) {
    e.getNode("fuel-consumed-lbs", 1).setDoubleValue(0);
    e.getNode("out-of-fuel", 1).setBoolValue(1);			# Begin with engines shutdown
    e.getNode("fuel-flow-gph", 1).setDoubleValue(0);
    e.getNode("fuel-flow-pph", 1).setDoubleValue(0);
  }

  foreach (var t; props.globals.getNode("/consumables/fuel", 1).getChildren("tank")) {
    if (!size(t.getChildren()))
      continue;           						# skip native_fdm.cxx generated zombie tanks
    append(tanks, t);
    init_double_prop(t, "level-gal_us", 0.0);
    init_double_prop(t, "level-lbs", 0.0);
    init_double_prop(t, "capacity-gal_us", 0.01);			# not zero (div/zero issue)
    # init_double_prop(t, "density-ppg", PPG);				# Deprecated by FG 2.4
    if (t.getNode("selected") == nil)					# This value should always be true
      t.getNode("selected", 1).setBoolValue(1);
  }

  settimer(fuel_startup, 2);						# Delay startup a bit to allow things to initialize
}


