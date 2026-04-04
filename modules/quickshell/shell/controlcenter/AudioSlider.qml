import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../../common" as Common

RowLayout {
    id: root

    required property var node
    required property string icon
    required property string label

    spacing: 8

    PwObjectTracker {
        objects: [node].filter(n => n !== null)
    }

    Text {
        text: root.icon
        font.family: Common.Theme.font.icons.family
        font.pixelSize: Common.Theme.font.sans.size
        color: root.muted ? Common.Theme.error : (root.value === 0 ? Common.Theme.textMuted : Common.Theme.foreground)
        Layout.alignment: Qt.AlignVCenter

        TapHandler {
            onTapped: if (root.node) root.node.audio.muted = !root.node.audio.muted
        }
    }

    Text {
        text: root.label
        font.family: Common.Theme.font.sans.family
        font.pixelSize: Common.Theme.font.sans.size - 2
        color: Common.Theme.textMuted
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: Math.round(root.value * 100) + "%"
        font.family: Common.Theme.font.mono.family
        font.pixelSize: Common.Theme.font.mono.size
        color: Common.Theme.textMuted
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 42
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        from: 0.0
        to: 1.0
        stepSize: 0.01
        value: root.value
        onMoved: slider.value = {
            if (root.node) {
                root.node.audio.volume = Math.max(0.0, Math.min(1.0, slider.value))
            }
        }

        background: Rectangle {
            x: 0
            y: slider.topPadding
            width: slider.availableWidth
            height: slider.availableHeight
            radius: height / 2
            color: Common.Theme.outline

            Rectangle {
                x: 0
                y: slider.topPadding
                width: slider.availableWidth * root.value
                height: slider.availableHeight
                radius: height / 2
                color: Common.Theme.accent
            }
        }

        handle: Rectangle {
            x: slider.value * slider.availableWidth - 1
            y: 0
            height: parent.height
            radius: height / 2
            color: Common.Theme.foreground

            TapHandler {
                onTapped: slider.increase()
            }

            TapHandler {
                onTapped: slider.decrease()
            }
        }
    }
}
