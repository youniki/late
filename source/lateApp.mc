using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.StringUtil as Str;


class lateApp extends App.AppBase {


	function initialize() {
        AppBase.initialize();
        onSettingsChanged();
	}

	function onSettingsChanged() {
		Ui.requestUpdate();
	}

    //! onStart() is called on application start up
    function onStart(state) {
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    }

	function getInitialView() {
		return [new lateView()];
	}


}