import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../common" as Common

Item {
    id: root

    property real brightness: 0.0
    property bool available: false
    property int maxBrightness: 1

    Process {
        id: getProc
        command: ["brightnessctl", "-m", "info"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const content = text.trim()
                const lines = content.split("\n")
                for (const line of lines) {
                    // brightnessctl -m format: device,class,current,max,percentage
                    const parts = line.split(",")
                    if (parts.length >= 5 && parts[1] === "backlight") {
                        maxBrightness = parseInt(parts[3])
                        brightness = parseInt(parts[2]) / maxBrightness
                        available = true
                        return
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

    visible: available
    implicitHeight: available ? layout.implicitHeight : 0

    ColumnLayout {
        id: layout
        anchors.fill: parent
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
                text: "Brightness"
                font.family: Common.Theme.font.sans.family
                font.pixelSize: Common.Theme.font.sans.size
                font.bold: true
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
            id: slider
            Layout.fillWidth: true
            from: 0.0
            to: 1.0
            stepSize: 0.01
            value: root.brightness

            onMoved: root.setBrightness(slider.value)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 4
                radius: height / 2
                color: Common.Theme.outline

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: height / 2
                    color: Common.Theme.accent
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * slider.availableWidth - width / 2
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 12
                height: 12
                radius: width / 2
                color: Common.Theme.accent
            }
        }
    }
}
