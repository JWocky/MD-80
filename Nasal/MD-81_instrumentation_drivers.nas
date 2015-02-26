# McDonnell Douglas MD-81
#
# Instrumentation Drivers
#
# Gary Neely aka 'Buckaroo'
#
# Support for backup Attitude Indicators
# Support for the RMI
# Support for nav freq decimal digits



# Support for the backup Attitude Indicators
#
# The backup AI presumably relies on either vacuum or electrically powered gyros which must
# be kept spinning to function. Some part of FG decrements the spin value, and some part
# increments it, but it seems to rely on an engine setting (RPM) that is not reliable or perhaps
# reasonable in the case of YASim jet engine models. Therefore I power it here by updating it
# every 5 seconds. In time this might become part of the electrical system.


var ai_spin	= props.globals.getNode("/instrumentation/attitude-indicator/spin");


var update_ai = func {
  ai_spin.setValue(1);
  settimer(update_ai, 5);
}




# Support to calculate RMI needle deflections based on mode (VOR/ADF)
# and beacon range. Simplifies RMI animations.
#
# Reads two custom properties:
#   /instrumentation/rmi-needle[0]/mode		(values 'vor'|'adf', default 'vor'), actually: 0|1 default 0
#   /instrumentation/rmi-needle[1]/mode		(values 'vor'|'adf', default 'vor'), actually: 0|1 default 0
#
# These should be set by cockpit switches to control the two RMI needles.
#
# Function writes to two custom properties:
#  /instrumentation/rmi-needle[0]/value
#  /instrumentation/rmi-needle[1]/value
#
# These are read by the RMI instrument animations.
#
# This code is based in part on code originally suggested by Wolfram Gottfried aka 'Yakko'.


var UPDATE_PERIOD	= 0.125;				# How often to update main loop in seconds (0 = framerate)

var rmi1	= props.globals.getNode("/instrumentation/rmi-needle[0]");
var rmi2	= props.globals.getNode("/instrumentation/rmi-needle[1]");
var adf1	= props.globals.getNode("/instrumentation/adf[0]");
var adf2	= props.globals.getNode("/instrumentation/adf[1]");
var nav1	= props.globals.getNode("/instrumentation/nav[0]");
var nav2	= props.globals.getNode("/instrumentation/nav[1]");
var heading	= props.globals.getNode("/orientation/heading-magnetic-deg");


var update_rmi = func {

  var needle1 = 90;						# Needle default off or out-of-range positions
  var needle2 = 270;
						
  if (rmi1.getNode("mode").getValue()) {			# Mode 1 = ADF
    if(adf1.getNode("in-range").getValue()) {
      needle1 = adf1.getNode("indicated-bearing-deg").getValue();
    }
  }
  else {							# Mode 0 = VOR
    if (nav1.getNode("in-range").getValue() and !nav1.getNode("has-gs").getValue()) {
      needle1 = nav1.getNode("heading-deg").getValue() - heading.getValue(); 
    }
  }

  if (rmi2.getNode("mode").getValue()) {			# Mode 1 = ADF
    if(adf2.getNode("in-range").getValue()) {
      needle2 = adf2.getNode("indicated-bearing-deg").getValue();
    }
  }
  else {							# Mode 0 = VOR
    if (nav2.getNode("in-range").getValue() and !nav2.getNode("has-gs").getValue()) {
      needle2 = nav2.getNode("heading-deg").getValue() - heading.getValue(); 
    }
  }

  rmi1.getNode("value").setValue(needle1);
  rmi2.getNode("value").setValue(needle2);

  settimer(update_rmi, UPDATE_PERIOD);
}



# Round-off errors screw-up the textranslate animation used to display digits. This is a problem
# for the NAV and COMM freq display. This seems to affect only decimal place digits. So here I'm using
# a listener to copy the MHz and KHz portions of a freq string to a separate integer values
# that are used by the animations.
#

var nav1selstr	= props.globals.getNode("/instrumentation/nav[0]/frequencies/selected-mhz-fmt");
var nav1selmhz	= props.globals.getNode("/instrumentation/nav[0]/frequencies/display-sel-mhz");
var nav1selkhz	= props.globals.getNode("/instrumentation/nav[0]/frequencies/display-sel-khz");
var nav2selstr	= props.globals.getNode("/instrumentation/nav[1]/frequencies/selected-mhz-fmt");
var nav2selmhz	= props.globals.getNode("/instrumentation/nav[1]/frequencies/display-sel-mhz");
var nav2selkhz	= props.globals.getNode("/instrumentation/nav[1]/frequencies/display-sel-khz");
var nav1sbystr	= props.globals.getNode("/instrumentation/nav[0]/frequencies/standby-mhz-fmt");
var nav1sbymhz	= props.globals.getNode("/instrumentation/nav[0]/frequencies/display-sby-mhz");
var nav1sbykhz	= props.globals.getNode("/instrumentation/nav[0]/frequencies/display-sby-khz");
var nav2sbystr	= props.globals.getNode("/instrumentation/nav[1]/frequencies/standby-mhz-fmt");
var nav2sbymhz	= props.globals.getNode("/instrumentation/nav[1]/frequencies/display-sby-mhz");
var nav2sbykhz	= props.globals.getNode("/instrumentation/nav[1]/frequencies/display-sby-khz");

							# This initializes the values
var navtemp = split(".",nav1selstr.getValue());
nav1selmhz.setValue(navtemp[0]);
nav1selkhz.setValue(navtemp[1]);
navtemp = split(".",nav2selstr.getValue());
nav2selmhz.setValue(navtemp[0]);
nav2selkhz.setValue(navtemp[1]);
navtemp = split(".",nav1sbystr.getValue());
nav1sbymhz.setValue(navtemp[0]);
nav1sbykhz.setValue(navtemp[1]);
navtemp = split(".",nav2sbystr.getValue());
nav2sbymhz.setValue(navtemp[0]);
nav2sbykhz.setValue(navtemp[1]);
							# And these make sure they're updated
setlistener(nav1selstr, func {
  var navtemp = split(".",nav1selstr.getValue());
  nav1selmhz.setValue(navtemp[0]);
  nav1selkhz.setValue(navtemp[1]);
});
setlistener(nav2selstr, func {
  var navtemp = split(".",nav2selstr.getValue());
  nav2selmhz.setValue(navtemp[0]);
  nav2selkhz.setValue(navtemp[1]);
});
setlistener(nav1sbystr, func {
  var navtemp = split(".",nav1sbystr.getValue());
  nav1sbymhz.setValue(navtemp[0]);
  nav1sbykhz.setValue(navtemp[1]);
});
setlistener(nav2sbystr, func {
  var navtemp = split(".",nav2sbystr.getValue());
  nav2sbymhz.setValue(navtemp[0]);
  nav2sbykhz.setValue(navtemp[1]);
});


var comm1sel	= props.globals.getNode("/instrumentation/comm[0]/frequencies/selected-mhz");
var comm1sby	= props.globals.getNode("/instrumentation/comm[0]/frequencies/standby-mhz");
var comm1selstr	= props.globals.getNode("/instrumentation/comm[0]/frequencies/selected-mhz-fmt");
var comm1sbystr	= props.globals.getNode("/instrumentation/comm[0]/frequencies/standby-mhz-fmt");
var comm1dselmhz= props.globals.getNode("/instrumentation/comm[0]/frequencies/display-sel-mhz");
var comm1dselkhz= props.globals.getNode("/instrumentation/comm[0]/frequencies/display-sel-khz");
var comm1dsbymhz= props.globals.getNode("/instrumentation/comm[0]/frequencies/display-sby-mhz");
var comm1dsbykhz= props.globals.getNode("/instrumentation/comm[0]/frequencies/display-sby-khz");

var comm2sel	= props.globals.getNode("/instrumentation/comm[1]/frequencies/selected-mhz");
var comm2sby	= props.globals.getNode("/instrumentation/comm[1]/frequencies/standby-mhz");
var comm2selstr	= props.globals.getNode("/instrumentation/comm[1]/frequencies/selected-mhz-fmt");
var comm2sbystr	= props.globals.getNode("/instrumentation/comm[1]/frequencies/standby-mhz-fmt");
var comm2dselmhz= props.globals.getNode("/instrumentation/comm[1]/frequencies/display-sel-mhz");
var comm2dselkhz= props.globals.getNode("/instrumentation/comm[1]/frequencies/display-sel-khz");
var comm2dsbymhz= props.globals.getNode("/instrumentation/comm[1]/frequencies/display-sby-mhz");
var comm2dsbykhz= props.globals.getNode("/instrumentation/comm[1]/frequencies/display-sby-khz");

							# Update support vars on comm change
setlistener(comm1sel, func {
  var commstr = sprintf("%.2f",comm1sel.getValue());	# String conversion
  var commtemp = split(".",commstr);			# Split into MHz and KHz
  comm1dselmhz.setValue(commtemp[0]);
  comm1dselkhz.setValue(commtemp[1]);
});
setlistener(comm1sby, func {
  var commstr = sprintf("%.2f",comm1sby.getValue());
  var commtemp = split(".",commstr);
  comm1dsbymhz.setValue(commtemp[0]);
  comm1dsbykhz.setValue(commtemp[1]);
});
setlistener(comm2sel, func {
  var commstr = sprintf("%.2f",comm2sel.getValue());
  var commtemp = split(".",commstr);
  comm2dselmhz.setValue(commtemp[0]);
  comm2dselkhz.setValue(commtemp[1]);
});
setlistener(comm2sby, func {
  var commstr = sprintf("%.2f",comm2sby.getValue());
  var commtemp = split(".",commstr);
  comm2dsbymhz.setValue(commtemp[0]);
  comm2dsbykhz.setValue(commtemp[1]);
});

							# Set comm support vars to startups
var update_comms = func {
  var commstr = "";
  var commtemp = 0;

  commstr = sprintf("%.2f",comm1sel.getValue());
  commtemp = split(".",commstr);
  comm1dselmhz.setValue(commtemp[0]);
  comm1dselkhz.setValue(commtemp[1]);
  commstr = sprintf("%.2f",comm1sby.getValue());
  commtemp = split(".",commstr);
  comm1dsbymhz.setValue(commtemp[0]);
  comm1dsbykhz.setValue(commtemp[1]);

  commstr = sprintf("%.2f",comm2sel.getValue());
  commtemp = split(".",commstr);
  comm2dselmhz.setValue(commtemp[0]);
  comm2dselkhz.setValue(commtemp[1]);
  commstr = sprintf("%.2f",comm2sby.getValue());
  commtemp = split(".",commstr);
  comm2dsbymhz.setValue(commtemp[0]);
  comm2dsbykhz.setValue(commtemp[1]);
}


var InstrumentationInit = func {
  settimer(update_rmi, 2);				# Delay startup a bit to allow things to initialize
  settimer(update_comms, 2);				# Delay startup a bit to allow things to initialize
  interpolate(ai_spin, 1, 15);				# Spin up the backup AI gyro
  settimer(update_ai, 20);				# Maintain spin on backup AI
}
