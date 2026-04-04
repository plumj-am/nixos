import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../common" as Common

Item {
    id: root

    property real brightness: 0.0
    property bool available: false

    FileView {
        id: maxFile
        path: "/sys/class/backlight"
        onLoadFailed: function (error) {
            console.log("BrightnessSlider: FileView load failed:", error)
        }
    }

    Process {
        id: getProc
        command: ["brightnessctl", "info"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const content = text.trim()
                const lines = content.split("\n")
                for (const line of lines) {
                    if (line.startsWith("(")) continue
                    const match = line.match(/\((\d+)\)/);
                    if (match) {
                        root.maxBrightness = parseInt(match[1])
                        root.brightness = parseInt(match[2]) / root.maxBrightness
                        root.available = true
                    }
                }
            }
        }
    }

    Process {
        id: setProc
        running: false
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        onTriggered: getProc.running = true
    }

    Component.onCompleted: {
        getProc.running = true
        pollTimer.start()
    }

    function setBrightness(value) {
        if (!available) return
        setProc.command = ["brightnessctl", "set", Math.round(value)]
        setProc.running = true
    }

    ColumnLayout {
        spacing: 8

        RowLayout {
            spacing: 8

            Text {
                text: "\uf185"
                font.family: Common.Theme.font.icons.family
                font.pixelSize: Common.Theme.font.sans.size
                color: Common.Theme.foreground
            }

            Text {
                text: Math.round(root.brightness * 100) + "%"
                font.family: Common.Theme.font.mono.family
                font.pixelSize: Common.Theme.font.mono.size
                color: Common.Theme.textMuted
                Layout.preferredWidth: 42
            }
        }

        Slider {
            Layout.fillWidth: true
            from: 0.0
            to: 1.0
            stepSize: 0.01
            value: root.brightness

            onMoved: function (val) {
                root.setBrightness(val)
            }

            background: Rectangle {
                x: 0
                y: slider.topPadding
                width: slider.availableWidth
                height: slider.height
                radius: height / 2
                color: Common.Theme.outline

                Rectangle {
                    x: slider.visualPosition * slider.availableWidth
                    height: slider.height
                    radius: height / 2
                    color: Common.Theme.accent
                }
            }

            handle: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding
                width: 2
                height: 2
                radius: 1
                color: Common.Theme.accent
            }

            TapHandler {
                onTapped: slider.increase()
            }

        }
    }
}
