import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../common" as Common

RowLayout {
    id: root

    required property var node
    required property string icon
    required property string label

    property real volume: node && node.audio ? (node.audio.volume || 0.0) : 0.0
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
            color: root.muted ? Common.Theme.error : (root.volume === 0 ? Common.Theme.textMuted : Common.Theme.foreground)
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
        Layout.preferredWidth: 48
    }

    Item {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: height / 2
            color: Common.Theme.outline

            Rectangle {
                width: parent.width * root.volume
                height: parent.height
                radius: height / 2
                color: Common.Theme.accent
            }
        }

        Rectangle {
            id: handle
            x: root.volume * (track.width - width)
            y: (track.height - height) / 2
            width: 12
            height: 12
            radius: width / 2
            color: Common.Theme.accent
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function setVolumeFromMouse(mouseX) {
                var v = Math.max(0.0, Math.min(1.0, mouseX / track.width))
                if (root.node && root.node.audio)
                    root.node.audio.volume = v
            }

            onPressed: function(mouse) { setVolumeFromMouse(mouse.x) }
            onPositionChanged: function(mouse) { if (pressed) setVolumeFromMouse(mouse.x) }
        }
    }

    Text {
        text: Math.round(root.volume * 100) + "%"
        font.family: Common.Theme.font.mono.family
        font.pixelSize: Common.Theme.font.mono.size
        color: Common.Theme.textMuted
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }
}
