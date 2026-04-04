import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../common" as Common

RowLayout {
    id: root

    spacing: 8

    property bool enabled: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled

    Text {
        text: "\uf293"
        font.family: Common.Theme.font.icons.family
        font.pixelSize: Common.Theme.font.sans.size
        color: root.enabled ? Common.Theme.accent : Common.Theme.foreground
    }

    Text {
        text: "Bluetooth"
        font.family: Common.Theme.font.sans.family
        font.pixelSize: Common.Theme.font.sans.size
        color: Common.Theme.foreground
        Layout.fillWidth: true
    }

    Text {
        visible: Bluetooth.devices.length > 0
        text: Bluetooth.devices.length + " device" + (Bluetooth.devices.length !== 1 ? "s" : "")
        font.family: Common.Theme.font.mono.family
        font.pixelSize: Common.Theme.font.mono.size
        color: Common.Theme.textMuted
    }

    Rectangle {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter
        radius: height / 2
        color: root.enabled ? Common.Theme.accent : Common.Theme.outline

        Rectangle {
            x: root.enabled ? parent.width - width - 2 : 2
            y: (parent.height - height) / 2
            width: 16
            height: 16
            radius: height / 2
            color: root.enabled ? Common.Theme.background : Common.Theme.textMuted

            Behavior on x { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
        }
    }
}
