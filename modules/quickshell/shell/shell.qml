//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "bar"
import "bar/widgets"
import "common" as Common
import "services" as Services
import "notifications" as Notifications
import "session" as Session
import "controlcenter" as ControlCenter
import "lock" as Lock

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: window

            required property var modelData
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

            property bool notifOpen: false
            property bool notifAutoOpened: false
            property bool mediaOpen: false
            property bool sessionOpen: false
            property bool controlCenterOpen: false

            Timer {
                id: notifAutoCloseTimer
                onTriggered: {
                    if (window.notifAutoOpened) {
                        window.notifOpen = false;
                        window.notifAutoOpened = false;
                        Notifications.NotificationServer.markAllSeen();
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

            property int topMargin: Common.Config.data.shell.enableOuterBorder ? Common.Config.data.shell.outerBorderSize : 0

            // Bar
            Bar {
                id: bar
                y: window.topMargin
                mediaDrawerOpen: window.mediaOpen
                notifDrawerOpen: window.notifOpen
                onNotificationClicked: {
                    window.notifOpen = !window.notifOpen;
                    window.notifAutoOpened = false;
                    window.mediaOpen = false;
                    window.sessionOpen = false;
                    window.controlCenterOpen = false;
                    notifAutoCloseTimer.stop();
                }
                onMediaClicked: {
                    window.mediaOpen = !window.mediaOpen;
                    window.notifOpen = false;
                    window.sessionOpen = false;
                    window.controlCenterOpen = false;
                }
                onSessionClicked: {
                    window.sessionOpen = !window.sessionOpen;
                    window.notifOpen = false;
                    window.mediaOpen = false;
                    window.controlCenterOpen = false;
                }
                onControlCenterClicked: {
                    window.controlCenterOpen = !window.controlCenterOpen;
                    window.notifOpen = false;
                    window.sessionOpen = false;
                    window.mediaOpen = false;
                }
                onThemeSwitchClicked: {
                    var cmd = Common.Theme.mode === "light" ? "dark" : "light";
                    Quickshell.execDetached({ command: ["tt", cmd, "--force"] });
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
                    window.notifOpen = false;
                    window.notifAutoOpened = false;
                    window.mediaOpen = false;
                    window.sessionOpen = false;
                    window.controlCenterOpen = false;
                    notifAutoCloseTimer.stop();
                    Notifications.NotificationServer.markAllSeen();
                }
            }

            Connections {
                target: Notifications.NotificationServer
                function onNotificationReceived(notification) {
                    if (!window.notifOpen) {
                        window.notifOpen = true;
                        window.notifAutoOpened = true;
                        window.mediaOpen = false;
                        window.sessionOpen = false;
                        window.controlCenterOpen = false;
                    }
                    if (window.notifAutoOpened) {
                        var timeout = notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : 8000;
                        notifAutoCloseTimer.interval = timeout;
                        notifAutoCloseTimer.restart();
                    }
                }
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
            item.screen = Quickshell.focusedScreen || Quickshell.screens[0];
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
            item.screen = Quickshell.focusedScreen || Quickshell.screens[0];
        }
    }

    Loader {
        id: lockLoader
        active: true
        source: "lock/Lock.qml"
    }

    function toggleLauncher() {
        if (clipboardLoader.item)
            clipboardLoader.item.isOpen = false;
        if (launcherLoader.item) {
            launcherLoader.item.screen = Quickshell.focusedScreen || Quickshell.screens[0];
            launcherLoader.item.isOpen = !launcherLoader.item.isOpen;
        }
    }

    function toggleClipboard() {
        if (launcherLoader.item)
            launcherLoader.item.isOpen = false;
        if (clipboardLoader.item) {
            clipboardLoader.item.screen = Quickshell.focusedScreen || Quickshell.screens[0];
            clipboardLoader.item.isOpen = !clipboardLoader.item.isOpen;
        }
    }

    Connections {
        target: Services.Niri
        function onLauncherToggleRequested() {
            toggleLauncher();
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            toggleLauncher();
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            toggleClipboard();
        }
    }

    IpcHandler {
        target: "notifications"
        function clear(): void {
            Notifications.NotificationServer.dismissAll();
        }
    }

    IpcHandler {
        target: "shell"
        function reload(): void {
            Quickshell.reload(false);
        }
        function reloadHard(): void {
            Quickshell.reload(true);
        }
    }
}
