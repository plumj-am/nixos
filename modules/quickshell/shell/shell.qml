//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "bar/widgets"
import "bar"
import "common" as Common
import "controlcenter" as ControlCenter
import "lock" as Lock
import "notifications" as Notifications
import "services" as Services
import "session" as Session

ShellRoot {
   function toggleLauncher() {
	  if (clipboardLoader.item)
		 clipboardLoader.item.isOpen = false
	  if (launcherLoader.item) {
		 launcherLoader.item.screen = Quickshell.focusedScreen || Quickshell.screens[0]
		 launcherLoader.item.isOpen = !launcherLoader.item.isOpen
	  }
   }

   function toggleClipboard() {
	  if (launcherLoader.item)
		 launcherLoader.item.isOpen = false
	  if (clipboardLoader.item) {
		 clipboardLoader.item.screen = Quickshell.focusedScreen || Quickshell.screens[0]
		 clipboardLoader.item.isOpen = !clipboardLoader.item.isOpen
	  }
   }

   Variants {
	  model: Quickshell.screens

	  delegate: PanelWindow {
		 id: window

		 required property var modelData
		 property bool notifOpen: false
		 property bool notifAutoOpened: false
		 property bool mediaOpen: false
		 property bool sessionOpen: false
		 property bool controlCenterOpen: false
		 property int topMargin: Common.Config.data.shell.enableOuterBorder ? Common.Config.data.shell.outerBorderSize :
																			  0

		 function toggleDrawer(name) {
			if (name === "notif") {
			   var wasOpen = notifOpen && !notifAutoOpened
			   notifOpen = !notifOpen
			   notifAutoOpened = false
			   if (!wasOpen && toastManagerLoader.item) {
				  toastManagerLoader.item.dismissAll()
			   }
			   mediaOpen = false
			   sessionOpen = false
			   controlCenterOpen = false
			   notifAutoCloseTimer.stop()
			} else if (name === "media") {
			   mediaOpen = !mediaOpen
			   notifOpen = false
			   notifAutoOpened = false
			   sessionOpen = false
			   controlCenterOpen = false
			} else if (name === "session") {
			   sessionOpen = !sessionOpen
			   notifOpen = false
			   notifAutoOpened = false
			   mediaOpen = false
			   controlCenterOpen = false
			} else if (name === "controlCenter") {
			   controlCenterOpen = !controlCenterOpen
			   notifOpen = false
			   notifAutoOpened = false
			   sessionOpen = false
			   mediaOpen = false
			}
		 }

		 screen: modelData
		 color: "transparent"
		 exclusionMode: ExclusionMode.Ignore
		 WlrLayershell.namespace: "quickshell:shell"

		 mask: Region {
			regions: childRegions.instances
			intersection: Intersection.Xor
		 }

		 Variants {
			id: childRegions

			model: window.contentItem.children

			delegate: Region {
			   required property Item modelData

			   item: modelData
			   intersection: Intersection.Xor
			}
		 }

		 anchors {
			left: true
			top: true
			right: true
			bottom: true
		 }

		 Timer {
			id: notifAutoCloseTimer

			onTriggered: {
			   if (window.notifAutoOpened) {
				  window.notifOpen = false
				  window.notifAutoOpened = false
				  Notifications.NotificationServer.markAllSeen()
			   }
			}
		 }

		 // Outer border rectangles (configurable)
		 Rectangle {
			visible: Common.Config.data.shell.enableOuterBorder
			anchors.left: parent.left
			width: Common.Config.data.shell.outerBorderSize
			height: parent.height
			color: Common.Theme.background
		 }

		 Rectangle {
			visible: Common.Config.data.shell.enableOuterBorder
			anchors.top: parent.top
			width: parent.width
			height: Common.Config.data.shell.outerBorderSize
			color: Common.Theme.background
		 }

		 Rectangle {
			visible: Common.Config.data.shell.enableOuterBorder
			anchors.right: parent.right
			width: Common.Config.data.shell.outerBorderSize
			height: parent.height
			color: Common.Theme.background
		 }

		 Rectangle {
			visible: Common.Config.data.shell.enableOuterBorder
			anchors.bottom: parent.bottom
			width: parent.width
			height: Common.Config.data.shell.outerBorderSize
			color: Common.Theme.background
		 }

		 // Bar
		 Bar {
			id: bar

			y: window.topMargin
			mediaDrawerOpen: window.mediaOpen
			notifDrawerOpen: window.notifOpen

			onNotificationClicked: window.toggleDrawer("notif")
			onMediaClicked: window.toggleDrawer("media")
			onSessionClicked: window.toggleDrawer("session")
			onControlCenterClicked: window.toggleDrawer("controlCenter")
			onThemeSwitchClicked: {
			   var cmd = Common.Theme.mode === "light" ? "dark" : "light"
			   Quickshell.execDetached({
										  command: ["tt", cmd, "--force"]
									   })
			}
		 }

		 // Notification drawer (top-right)
		 Notifications.NotificationDrawer {
			id: notifDrawer

			open: window.notifOpen
			popupMode: window.notifAutoOpened
			anchors.top: parent.top
			anchors.topMargin: window.topMargin + bar.barSize
			anchors.right: parent.right
		 }

		 // Media drawer (top-left)
		 MediaDrawer {
			id: mediaDrawer

			open: window.mediaOpen
			anchors.top: parent.top
			anchors.topMargin: window.topMargin + bar.barSize
			anchors.left: parent.left
		 }

		 // Session drawer (right side)
		 Session.Session {
			id: sessionDrawer

			open: window.sessionOpen
		 }

		 // Control center drawer (top-right, below bar)
		 ControlCenter.ControlCenter {
			id: controlCenter

			open: window.controlCenterOpen
			anchors.top: parent.top
			anchors.topMargin: window.topMargin + bar.barSize
			anchors.right: parent.right
		 }

		 // Click outside drawers to close (covers empty areas only due to mask)
		 MouseArea {
			anchors.fill: parent
			z: -1
			acceptedButtons: Qt.AllButtons

			onClicked: function (mouse) {
			   notifOpen = false
			   notifAutoOpened = false
			   mediaOpen = false
			   sessionOpen = false
			   controlCenterOpen = false
			   notifAutoCloseTimer.stop()
			   Notifications.NotificationServer.markAllSeen()
			}
		 }

		 Connections {
			target: Notifications.NotificationServer
			// Notifications now appear as toasts via ToastManager.
			// Drawer only opens via manual interaction (onNotificationClicked).
		 }
	  }
   }

   // Exclusion zone: reserves space at top so windows tile below the bar
   Variants {
	  model: Quickshell.screens

	  delegate: PanelWindow {
		 required property var modelData

		 screen: modelData
		 anchors.top: true
		 color: "transparent"
		 WlrLayershell.namespace: "quickshell:topExclusionZone"
		 exclusiveZone: Common.Config.data.bar.size
	  }
   }

   // Launcher stays as separate overlay PanelWindow
   Loader {
	  id: launcherLoader

	  active: true
	  source: "launcher/Launcher.qml"

	  onLoaded: {
		 item.screen = Quickshell.focusedScreen || Quickshell.screens[0]
	  }
   }

   Loader {
	  id: toastManagerLoader

	  active: true
	  source: "notifications/ToastManager.qml"
   }

   Loader {
	  id: clipboardLoader

	  active: true
	  source: "clipboard/Clipboard.qml"

	  onLoaded: {
		 item.screen = Quickshell.focusedScreen || Quickshell.screens[0]
	  }
   }

   Loader {
	  id: lockLoader

	  active: true
	  source: "lock/Lock.qml"
   }

   Connections {
	  function onLauncherToggleRequested() {
		 toggleLauncher()
	  }

	  target: Services.Niri
   }

   IpcHandler {
	  function toggle(): void {
	  toggleLauncher()
   }

	  target: "launcher"
   }

   IpcHandler {
	  function toggle(): void {
	  toggleClipboard()
   }

	  target: "clipboard"
   }

   IpcHandler {
	  function clear(): void {
	  Notifications.NotificationServer.dismissAll()
   }

	  target: "notifications"
   }

   IpcHandler {
	  function reload(): void {
	  Quickshell.reload(false)
   }

	  function reloadHard(): void {
								Quickshell.reload(true)
							 }

	  target: "shell"
   }
}
