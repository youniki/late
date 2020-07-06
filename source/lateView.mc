using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Activity as Activity;
using Toybox.Math as Math;
//using Toybox.ActivityMonitor as ActivityMonitor;
// its not an app 
//using Toybox.Application as App;


class lateView extends Ui.WatchFace {
	hidden const CENTER = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
	hidden var dateForm; hidden var batThreshold = 33;
	hidden var centerX; hidden var centerY; hidden var height; hidden var width;
	hidden var color; hidden var lightFGColor = 0xFF00FF; hidden var darkFGColor = Gfx.COLOR_PINK; hidden var backgroundColor = Gfx.COLOR_BLACK;
	var activity = 0; var dataLoading = false;
	hidden var icon = null; hidden var sunrs = null; hidden var sunst = null; //hidden var iconNotification;
	hidden var clockTime; hidden var utcOffset; hidden var day = -1;
	hidden var fontSmall = null; hidden var fontMinutes = null; hidden var fontHours = null; hidden var fontCondensed = null;
	hidden var dateY = null; hidden var radius; hidden var circleWidth = 3; hidden var dialSize = 0; hidden var batteryY; hidden var activityY; //hidden var notifY;
	// redraw full watchface
	hidden var redrawAll=2; // 2: 2 clearDC() because of lag of refresh of the screen ?
	hidden var lastRedrawMin=-1;
	//hidden var dataCount=0;hidden var wakeCount=0;
	var weekday_abbr_cache = ["Di", "Mi", "Do", "Fr", "Sa", "So", "Mo"];

	function initialize (){
		WatchFace.initialize();
		var set=Sys.getDeviceSettings();
		height = set.screenHeight;
		width = set.screenWidth;
		centerX = set.screenWidth >> 1;
		centerY = height >> 1;
		clockTime = Sys.getClockTime();
	}
	function onLayout (dc) {
		loadSettings();
	}

	function setLayoutVars(){
		//Sys.println("Layout free memory: "+Sys.getSystemStats().freeMemory);
		if(dialSize>0){ // strong design
			fontHours = Ui.loadResource(Rez.Fonts.HoursStrong);
			fontMinutes = Ui.loadResource(Rez.Fonts.MinuteStrong);
			fontSmall = Ui.loadResource(Rez.Fonts.SmallStrong);
			if(height>218){
				dateY = centerY-Gfx.getFontHeight(fontHours)>>1-Gfx.getFontHeight(fontMinutes)-7;
				radius = 89;
				circleWidth=circleWidth*3+1;
				batteryY=height-15 ;
			} else {
				dateY = centerY-Gfx.getFontHeight(fontHours)>>1-Gfx.getFontHeight(fontMinutes)-6;
				radius = 81;
				batteryY=height-15;
				circleWidth=circleWidth*3;
			}		
		} else { // elegant design
			fontHours = Ui.loadResource(Rez.Fonts.Hours);
			fontMinutes = Ui.loadResource(Rez.Fonts.Minute);
			fontSmall = Ui.loadResource(Rez.Fonts.Small);
			if(height>218){
				dateY = centerY-90-(Gfx.getFontHeight(fontSmall)>>1);
				radius = 63;	
				batteryY = centerY+38;	
			} else {
				dateY = centerY-80-(Gfx.getFontHeight(fontSmall)>>1);
				radius = 55;
				batteryY = centerY+33;
			}
		}

		if(activity>0){
			fontCondensed = Ui.loadResource(Rez.Fonts.Condensed);
			if(dialSize==0){
				activityY = (height>180) ? height-Gfx.getFontHeight(fontCondensed)-10 : centerY+80-Gfx.getFontHeight(fontCondensed)>>1 ;
				if(activity == 6){
					if(dataLoading){
						var eventHeight = Gfx.getFontHeight(fontCondensed)-1;
						activityY = (centerY-radius+10)>>2 - eventHeight + centerY+radius+10;

					} else { 
						activity = 0;
					}
				}
			} else {
				activityY= centerY+Gfx.getFontHeight(fontHours)>>1+5;
			}
		}
		if(dataLoading && activity != 6){

		}

	}

	function loadSettings(){
		//Sys.println("loadSettings");
		dateForm = 1;
		activity = 1;
		batThreshold = 100;
		circleWidth = 3;
		dialSize = 0;

		var palette = [
			[0xFF0000, 0xFFAA00, 0x00FF00, 0x00AAFF, 0xFF00FF, 0xAAAAAA],
			[0xAA0000, 0xFF5500, 0x00AA00, 0x0000FF, 0xAA00FF, 0x555555], 
			[0xAA0055, 0xFFFF00, 0x55FFAA, 0x00AAAA, 0x5500FF, 0xAAFFFF]
		];
		var tone = 0;
		var mainColor = 4;
		color = palette[tone][mainColor];



		if(activity>0){ 
			if(activity == 1) { icon = Ui.loadResource(Rez.Drawables.Steps); }
			else if(activity == 2) { icon = Ui.loadResource(Rez.Drawables.Cal); }
			else if(activity >= 3 && !(ActivityMonitor.getInfo() has :activeMinutesDay)){ 
				activity = 0;   // reset not supported activities
			} else if(activity <= 4) { icon = Ui.loadResource(Rez.Drawables.Minutes); }
			else if(activity == 5) { icon = Ui.loadResource(Rez.Drawables.Floors); }
		}
		redrawAll = 2;
		setLayoutVars();
	}

	//! Called when this View is brought to the foreground. Restore the state of this View and prepare it to be shown. This includes loading resources into memory.
	function onShow() {
		///Sys.println("onShow");
		redrawAll=2;
	}
	
	//! Called when this View is removed from the screen. Save the state of this View here. This includes freeing resources from memory.
	function onHide(){
		//Sys.println("onHide");
		redrawAll=0;
	}
	
	//! The user has just looked at their watch. Timers and animations may be started here.
	function onExitSleep(){
		///Sys.println("onExitSleep");
		//wakeCount++;
		redrawAll=1;
	}

	//! Terminate any active timers and prepare for slow updates.
	function onEnterSleep(){
	}

	//! Update the view
	function onUpdate (dc) {
		darkFGColor = Gfx.COLOR_PINK;
		lightFGColor = 0xFFAAFF;
		///Sys.println("onUpdate "+redrawAll);
		clockTime = Sys.getClockTime();
		if (lastRedrawMin != clockTime.min && redrawAll==0) { redrawAll = 1; }
		//var ms = [Sys.getTimer()];
		//if (redrawAll>0){
			dc.setColor(backgroundColor, backgroundColor);
			dc.clear();
			lastRedrawMin=clockTime.min;
			var info = Calendar.info(Time.now(), Time.FORMAT_MEDIUM);
			var h=clockTime.hour;

			// draw hour
			var set = Sys.getDeviceSettings();
			if(set.is24Hour == false){
				if(h>11){ h-=12;}
				if(0==h){ h=12;}
			}
			dc.setColor(darkFGColor, Gfx.COLOR_TRANSPARENT);
			dc.drawText(centerX, centerY-(dc.getFontHeight(fontHours)>>1), fontHours, h.format("%0.1d"), Gfx.TEXT_JUSTIFY_CENTER);	
			drawBatteryLevel(dc);
			drawMinuteArc(dc);
			if(centerY>89){
				dc.setColor(lightFGColor, Gfx.COLOR_TRANSPARENT);
				var text = "";
	
				
				if(dateForm != null){
					// text = Lang.format("$1$ ", ((dateForm == 0) ? [info.month] : [info.day_of_week]) );
					text = Lang.format("$1$ ", ((dateForm == 0) ? [info.month] : [weekday_abbr_cache[info.day]]) );
				}
				text += info.day.format("%0.1d");
				// dc.drawText(centerX, dateY, fontSmall, text, Gfx.TEXT_JUSTIFY_CENTER);
				dc.drawText(0, (height/2)-10, fontSmall, text, Gfx.TEXT_JUSTIFY_LEFT);
				if(activity > 0){
					text = ActivityMonitor.getInfo();
					if(activity == 1){ text = text.steps.toString(); }
					else if(activity == 2){ text = humanizeNumber(text.calories); }
					else if(activity == 3){ text = (text.activeMinutesDay.total.toString());} // moderate + vigorous
					else if(activity == 4){ text = humanizeNumber(text.activeMinutesWeek.total); }
					else if(activity == 5){ text = (text.floorsClimbed.toString()); }
					else {text = "";}

					dc.setColor(lightFGColor, Gfx.COLOR_TRANSPARENT);
					activityY = 20;
					if(activity < 6){
						dc.drawText(centerX + icon.getWidth()>>1, activityY, fontCondensed, text, Gfx.TEXT_JUSTIFY_CENTER); 
						dc.drawBitmap(centerX - dc.getTextWidthInPixels(text, fontCondensed)>>1 - icon.getWidth()>>1-4, activityY+5, icon);
					} 
				}
			}
		dc.setColor(lightFGColor, Gfx.COLOR_TRANSPARENT);
		dc.drawText(centerX, 170, fontSmall, "STAY,", Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText(centerX, 190, fontSmall, "liebste Nici", Gfx.TEXT_JUSTIFY_CENTER);
	}



	(:data)
	function humanizeNumber(number){
		if(number>1000) {
			return (number.toFloat()/1000).format("%1.1f")+"k";
		} else {
			return number.toString();
		}
	}


	(:data)
	function getMarkerCoords(event, tillStart){
		var secondsFromLastHour = event - (Time.now().value()-(clockTime.min*60+clockTime.sec));
		var a = (secondsFromLastHour).toFloat()/Calendar.SECONDS_PER_HOUR * 2*Math.PI;
		var r = tillStart>=120 || clockTime.min<10 ? radius : radius-Gfx.getFontHeight(fontMinutes)>>1-1;
		return [centerX+(r*Math.sin(a)), centerY-(r*Math.cos(a))];
	}

	function drawMinuteArc (dc){

		var minutes = clockTime.min; 
		///Sys.println(minutes+ " mins mem " +Sys.getSystemStats().freeMemory);
		var angle =  minutes/60.0*2*Math.PI;
		var cos = Math.cos(angle);
		var sin = Math.sin(angle);
		var offset=0;
		var gap=0;


		//dc.setColor(Gfx.color, Gfx.COLOR_TRANSPARENT);
		//use hard coded pink instead of config color
		dc.setColor(darkFGColor, Gfx.COLOR_TRANSPARENT);
		dc.drawText(centerX + (radius * sin), centerY - (radius * cos) , fontMinutes, minutes /*clockTime.min.format("%0.1d")*/, CENTER);
		
		
		if(minutes>0){
			dc.setColor(darkFGColor, backgroundColor);
			dc.setPenWidth(circleWidth);
			
			/* kerning values not to have ugly gaps between arc and minutes
			minute:padding px
			1:4 
			2-6:6 
			7-9:8 
			10-11:10 
			12-22:9 
			23-51:10 
			52-59:12
			59:-3*/

			// correct font kerning not to have wild gaps between arc and number
			if(minutes>=10){
				if(minutes>=52){
					offset=13;
					if(minutes==59){
						gap=4;	
					} 
				} else {
					if(minutes>=12&&minutes<=22){
						offset=10;
					}
					else {
						offset=12;
					}
				}
			} else {
				if(minutes>=7){
					offset=9;
				} else {
					if(minutes==1){
						offset=5;
					} else {
						offset=7;
					}
				}

			}
			dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 90-gap, 90-minutes*6+offset);
		}
		
	}

	function drawBatteryLevel (dc){
		var bat = Sys.getSystemStats().battery;
		if(bat<=batThreshold){

			var xPos = centerX-10;
			// var yPos = batteryY;
			var yPos = 0;
			
			// print the remaining %
			//var str = bat.format("%d") + "%";
			dc.setColor(backgroundColor, backgroundColor);
			dc.setPenWidth(1);
			dc.fillRectangle(xPos,yPos,20, 10);

			if(bat<=15){
				dc.setColor(Gfx.COLOR_RED, backgroundColor);
			} else {
				dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor);
			}
				
			// draw the battery

			dc.drawRectangle(xPos, yPos, 19, 10);
			dc.fillRectangle(xPos + 19, yPos + 3, 1, 4);

			var lvl = floor((15.0 * (bat / 99.0)));
			if (1.0 <= lvl) { dc.fillRectangle(xPos + 2, yPos + 2, lvl, 6); }
			else {
				dc.setColor(Gfx.COLOR_ORANGE, backgroundColor);
				dc.fillRectangle(xPos + 1, yPos + 1, 1, 8);
			}
		}
	}

function floor (f){
    if (f instanceof Toybox.Lang.Float){
         return f.toNumber();   
    }
    return -1;
} 
 
function ceil (f){
    var f2=-f;
    if (f2 instanceof Toybox.Lang.Float){
        return f2.toNumber();   
    }
    return -1;
}


}