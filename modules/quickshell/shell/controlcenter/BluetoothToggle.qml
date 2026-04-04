import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../common" as Common

RowLayout {
    id: root

    spacing: 8

    RowLayout {
        spacing: 8

        Text {
            text: "\uf293"
            font.family: Common.Theme.font.icons.family
            font.pixelSize: Common.Theme.font.sans.size
            color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Common.Theme.accent : Common.Theme.foreground

            TapHandler {
                onTapped: {
                    if (Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
            }
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
    }
}
