import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import "../common" as Common

WlSessionLock {
    id: lock

    property bool unlocking: false

    LockSurface {
        id: surface
    }

    PamContext {
        id: pam
        config: "lock"
        configDirectory: "root:/lock/pam.d"

        onCompleted: function (result) {
            if (result === PamResult.Success) {
                lock.unlocking = true;
                lock.locked = false;
                lock.unlocking = false;
            } else {
                surface.clearInput();
                surface.showError();
            }
        }

        onPamMessage: {
            if (responseRequired) {
                surface.setPasswordPrompt();
            }
        }
    }

    IpcHandler {
        target: "lock"
        function toggle(): void {
            if (lock.locked) {
                lock.locked = false;
            } else {
                lock.locked = true;
            }
        }
    }
}
