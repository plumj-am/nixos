//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "bar"
import "common" as Common
import "services" as Services
import "notifications" as Notifications

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property var modelData
            screen: modelData
        }
    }

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
}
