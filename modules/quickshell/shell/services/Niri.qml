pragma Singleton
import Niri 0.1
import QtQuick

QtObject {
   id: niriWrapper

   property Niri niri: Niri {
	  Component.onCompleted: connect()
	  onConnected: console.log("Connected to niri")
	  onErrorOccurred: function (error) {
		 console.error("Niri error:", error)
	  }
   }
   readonly property var focusedWindow: niri.focusedWindow

   signal launcherToggleRequested

   function toggleLauncher() {
	  launcherToggleRequested()
   }
}
