import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "." as Local
import "../common" as Common
import "../services" as Services

Item {
    id: root

    property bool open: false

    implicitWidth: 360
    implicitHeight: open ? contentColumn.implicitHeight + 24 : 0
    visible: implicitHeight > 0

    Behavior on implicitHeight {
        Common.NAnim {}
    }

    Common.Corner {
        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: root.open ? Common.Config.data.shell.cornerRadius : 0
        color: Common.Theme.background
    }

    Common.Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        radius: root.open ? Common.Config.data.shell.cornerRadius : 0
        color: Common.Theme.background
    }

    Rectangle {
        anchors.fill: parent
        color: Common.Theme.background
        radius: 0
        bottomLeftRadius: Common.Theme.radius.big
        clip: true

        MouseArea {
            z: -1
            anchors.fill: parent
            onPressed: function(mouse) { mouse.accepted = true }
        }

        ColumnLayout {
            z: 0
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Audio
            Text {
                text: "Audio"
                font.family: Common.Theme.font.sans.family
                font.pixelSize: Common.Theme.font.sans.size
                font.bold: true
                color: Common.Theme.foreground
            }

            Local.AudioSlider {
                Layout.fillWidth: true
                node: Pipewire.defaultAudioSink
                icon: {
                    if (!node || !node.audio) return "\uf026";
                    if (node.audio.muted || node.audio.volume === 0) return "\uf026";
                    if (node.audio.volume < 0.4) return "\uf027";
                    return "\uf028";
                }
                label: "Output"
            }

            Local.AudioSlider {
                Layout.fillWidth: true
                node: Pipewire.defaultAudioSource
                icon: "\uf130"
                label: "Input"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Common.Theme.outline
            }

            // Brightness
            Local.BrightnessSlider {
                id: brightnessSlider
                Layout.fillWidth: true
            }

            Rectangle {
                visible: brightnessSlider.available
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Common.Theme.outline
            }

            // Bluetooth
            Local.BluetoothToggle {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Common.Theme.outline
            }

            // Network
            Text {
                text: "Network"
                font.family: Common.Theme.font.sans.family
                font.pixelSize: Common.Theme.font.sans.size
                font.bold: true
                color: Common.Theme.foreground
            }

            Local.NetworkInfo {
                Layout.fillWidth: true
            }
        }
    }
}
