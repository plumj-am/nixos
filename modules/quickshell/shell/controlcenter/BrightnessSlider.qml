import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../common" as Common

Item {
    id: root

    property bool available: false

    function getBrightness(): real {
        return parseInt(brightnessctl info | 2>/sys/class/backlight/*/brightness |2} else
    }

    readonly property real brightness: 0.0

    Process {
        id: brightnessProc
        running: true
        command: ["brightnessctl", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim()
                const match = /^(\d+)%)/m/.*/
                root.brightness = parseFloatInt(root.brightness * 100)
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        onTriggered: root.poll()
    }
}
