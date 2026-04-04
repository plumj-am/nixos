import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../common" as Common

RowLayout {
    id: root

    required property var node
    required property string icon
    required property string label

    property real value: node && node.audio ? (node.audio.volume || 0.0) : 0.0
    property bool muted: node && node.audio ? node.audio.muted : false

    spacing: 8

    PwObjectTracker {
        objects: [node].filter(n => n !== null)
    }

    Rectangle {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        Layout.alignment: Qt.AlignVCenter
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: Common.Theme.font.icons.family
            font.pixelSize: Common.Theme.font.sans.size
            color: root.muted ? Common.Theme.error : (root.value === 0 ? Common.Theme.textMuted : Common.Theme.foreground)
        }

        TapHandler {
            onTapped: if (root.node && root.node.audio) root.node.audio.muted = !root.node.audio.muted
        }
    }

    Text {
        text: root.label
        font.family: Common.Theme.font.sans.family
        font.pixelSize: Common.Theme.font.sans.size - 2
        color: Common.Theme.textMuted
        Layout.alignment: Qt.AlignVCenter
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        from: 0.0
        to: 1.0
        stepSize: 0.01

        Binding {
            target: slider
            property: "value"
            value: root.value
            when: !slider.pressed
        }

        onMoved: {
            if (root.node && root.node.audio)
                root.node.audio.volume = Math.max(0.0, Math.min(1.0, slider.value))
        }

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

    Text {
        text: Math.round((slider.pressed ? slider.value : root.value) * 100) + "%"
        font.family: Common.Theme.font.mono.family
        font.pixelSize: Common.Theme.font.mono.size
        color: Common.Theme.textMuted
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }
}
