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

            anchors {
                left: true
                top: true
                right: true
                bottom: true
            }

            property bool notifOpen: false
            property bool mediaOpen: false
            property bool sessionOpen: false

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

            property int topMargin: Common.Config.data.shell.enableOuterBorder
                ? Common.Config.data.shell.outerBorderSize : 0

            // Bar
            Bar {
                id: bar
                y: window.topMargin
                onNotificationClicked: {
                    window.notifOpen = !window.notifOpen
                    window.mediaOpen = false
                    window.sessionOpen = false
                }
                onMediaClicked: {
                    window.mediaOpen = !window.mediaOpen
                    window.notifOpen = false
                    window.sessionOpen = false
                }
                onSessionClicked: {
                    window.sessionOpen = !window.sessionOpen
                    window.notifOpen = false
                    window.mediaOpen = false
                }
            }

            // Notification drawer (top-right)
            Notifications.NotificationDrawer {
                id: notifDrawer
                open: window.notifOpen
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

            // Background click handler to close drawers
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.AllButtons
                onClicked: function(mouse) {
                    window.notifOpen = false
                    window.mediaOpen = false
                    window.sessionOpen = false
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
            anchors.left: true
            anchors.right: true
            exclusionMode: ExclusionMode.Normal
            explicitExclusiveZone: Common.Config.data.bar.size
            color: "transparent"
            height: 1
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

    function toggleLauncher() {
        if (launcherLoader.item) {
            launcherLoader.item.screen = Quickshell.focusedScreen || Quickshell.screens[0];
            launcherLoader.item.isOpen = !launcherLoader.item.isOpen;
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
    }
}
