import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import "../common" as Common

WlSessionLock {
    id: lock

    LockSurface {
        id: surface
        pam: pam
    }

    PamContext {
        id: pam
        config: "lock"
        configDirectory: "root:/lock/pam.d"

        onCompleted: function (result) {
            if (result === PamResult.Success) {
                lock.locked = false;
            } else {
                surface.clearInput();
                surface.showError();
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
