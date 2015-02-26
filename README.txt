McDonnell Douglas MD-81
-----------------------

The MD-81 is provided as-is, with no guarantees. I am not a pilot, and though I've been a passenger in MD-80's and their B717 descendents, I have no specialized knowledge.

The MD-80 series has three variants: the 81, 82, and 83. I chose the 81 as it is an earlier incarnation (I am more interested in historic aircraft than contemporary stuff) and is not specialized for longer range or hot/high-altitude fields. 81's also typically have older cockpits featuring simpler instruments more familiar to me, though it should be noted that many 81's feature upgrades with glass displays, MFDs, etc. Originally the 81 featured the Pratt & Whitney JT8D-209, but most have been upgraded to the JT8D-217 with 1500 lbs more thrust each. I model the latter engine, as the former is pretty wimpy and few if any MD-81's are still using it. My MD-81 model also features the later 'beaver' or 'screwdriver' tail, which has a lower drag than the original conical tail cone and is a refit to many if not most MD-81s.

The flight model uses YASim for its FDM. I have no idea if it flies anything like the real aircraft and small hope that it does, but I have carefully checked the geometry against available sources and worked to get the weights and balance to something reasonable, so it should fly much like what you would expect for something with this geometry. It isn't quite capable of the real aircraft's max cruise speed at less than 100% throttle. See the problem section below for details.

Unlike my Lockheed 1049H and Grumman Goose models, I had very limited information to build this model. Much is proprietary, so sources are difficult to find. I do not like relying on the little 3-view drawings commonly available (which are often wrong), so where possible I gathered data from other sources. In many cases I took measurements from high-resolution photos using a ruler and a pair of dividers, interpolating against known dimensions. The MD-80 series airfoils appear to be proprietary, so I substituted a generic thin profile semi-symmetrical wing.

This simulation was created using publicly available information. It contains no proprietary or restricted data, is not endorsed by any manufacturer, and is meant for entertainment purposes only. This model is currently available as free for personal, non-commercial use. Please contact me if interested in using any portions of this model.



Standard Load

Maximum take-off weight for the MD-81 is 140,000 lbs. The default load is configured to about 120,000 lbs (60 tons) to give you some margin to get used to the aircraft. You can alter this with the Equipment->Fuel and Payload settings. Eventually I would like to refine the passenger/cargo settings to break them up into different stations to allow more experimentation with CG positions.


Engine Starting

The engine start-up procedures are now very close to the real thing. The procedures are not difficult, but are deserving of their own separate explanation. See HOWTO_engine_starting or use the MD-81 menu for Magic Engine Start.


Flying

For take-off, set flaps to 11 degrees (two clicks of the flaps key) and rotate at 140-145 knots. For best results with the current FDM, after initial climb-out, climb by maintaining a gentle pitch of 5 degrees with clean flight surfaces and minimal elevator, holding pitch with trim only until you reach your target altitude. If you do this, the plane will achieve 35,000' with close to realistic cruise airspeed of around mach 0.72. The real plane is capable of a bit better cruise, mach 0.75. Don't try to force the plane up too fast or airspeed and performance will drop way off.

When landing, set flaps to 28 degrees and touch down around 135 knots. Be careful not to pitch up too high when landing; you should be able to see the field well all the way down. Max landing weight is 128,000, so keep that in mind if you play with the weight and fuel settings.

You have thrust reversers using the DEL key. Slats are automated and slaved to flap settings.

Flap settings: Flap detents are set to 5, 11, 15, 20, 28 and 40 degrees. 11 or 15 degrees are standard for takeoff, 28 or 40 for landing.


Fuel Management

The model now incorporates full fuel management procedures for all three tanks. You can fly without knowing any of this, but for better than short-range flights, you'll need to know the systems. See HOWTO_fuel_management for information about your MD-81's fuel tanks and fuel system.


Spoilers

Spoilers are extended with the k key and retracted with the j key. Spoiler operation is a little complicated, but essentially there are two modes, flight and ground. When flying you may only extend spoilers about half-way, and the inboard spoilers will not activate. When in contact with the ground, spoilers may be fully deployed, and include the inboard spoilers.

Spoilers are locked-out when flaps are set greater than 11 degrees. Note that in the real aircraft, the lockout is 8 degrees-- I'm allowing a bit more to account for the current lack of fully analog flap settings.

You may arm the spoilers for automatic ground deployment with the ctrl-k key. When so activated, the spoilers will automagically fully deploy when your main gear touch down. This dumps a lot of lift and is an excellent way to make your plane stick to the ground. To disarm this feature, use the ctrl-j key. You may also use the MD-81 menu options to do the same. Spoilers may be armed on the ground before takeoff.

You may see flight spoilers move even when not deployed. This is normal, as spoilers are coupled to assist aileron action.


Automatic Braking System (ABS)

See HOWTO_autobrakes for information on using this system.


Tabbed Controls

On the MD-80 series, elevators and ailerons are 'flown' into position by small control tabs on the trailing edge. Because of this, you may not see the aileron and elevator movements you expect to see when on the ground. Until enough air is moving over the flight surfaces to actuate the ailerons and elevators, these surfaces will not move much. This is correct behavior for the MD-80 series. Note that the rudder is normally hydraulically actuated, though tabbed control serves as a backup.

You may see your flight surfaces take on odd positions when on the ground. Again, this is normal and depends on the wind and the attitude of your plane.


Primary Flight Display and Navigational Display

These are your two electronic flight instrument systems (EFIS). A couple of things to note: you can adjust your display brightness using the middle and lower knobs on the gadget to the left of the altimeter. Your brightness settings are saved if you use exit using the Flihtgear menu. The PFD features a glideslope and localizer scale which is activated upon selecting an ILS signal. The navigational display (EHSI) features a DME that appears in the upper left corner when a localizer is seleted. It also features a Decision Height display in the lower left (see below). The EHSI also features an optional display of rudder and throttle positions which may be activated using the MD-81 menu or by clicking on the 'Test' button on the gadget to the right of the altimeter. The is not a realistic feature, but is meant to be a visual feedback aid. This setting is also saved on exit.


Decision Height

You can set a decision height (DH) up to 990 feet using the top knob on the little gadget to the right of the altimeter. The height will appear in the lower left corner of your EHSI. When your altitude above ground reaches this height or less, the display will change to amber and the numbers will show your height above ground. Setting DH to 0 will turn off the display. Note that DH should be set in flight; setting DH on the ground isn't practical.


Glareshield Controls

The upper panel known as the glareshield features controls for lights, setting NAV1 (pilot side) frequency and course, NAV2 (copilot side) frequency and course, and autopilot and flight director controls. Currently only nav settings, autothrottle and nav lights are available. Note that NAV1 is displayed on the EHSI; NAV2 is only used on the RMI.


Known Problems and Other Stuff:

The model isn't quite capable of the maximum cruise speeds of the MD-81. Attempts to get perfect top-end cruise speeds through the FDM have tended to seriously diminish approach handling, so I sacrifice a little top-end performance to retain good approach handling for all weight and balance situations.

The nose gear still rides slightly too high, but is better than the previous release. YASim's compression algorithm doesn't allow me to let the nose ride at rest where it should and still give the full uncompressed extension, so the nose tends to sit too high at rest. (Frankly I'm not clear how the real aircraft gets away with such a low-riding compression.)

Two liveries are provided with this release, American Airlines, and Scandinavian Airlines. Both were created by yours-truly. It's been pointed out that the American Airlines livery does not have the "MD-80" logo on the sides of the engine nacelles. I'm aware of that, as would anyone be who has studied hundreds of pics for research. The logo is there because this is the default livery, and I'm less interested in liveries than I am in promoting the aircraft itself. Feel free to create your own livery variations.



Acknowledgements

Special thanks go to Peter "Farmboy" Brown for his help and knowledge in playtesting the model. The FDM owes much to his advice and feedback.

Thanks to Syd Adams for allowing me to use and modify support textures from a his EADI and EHSI out of the s76c model.

I would like to thank Melchior Franz for his Blender plug-in that imports YASim data as Blender objects. This tool was invaluable for checking my flight model work.


---
Gary R. Neely "Buckaroo"
December 2010
grneely@gmail.com
