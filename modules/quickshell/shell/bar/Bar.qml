 import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "widgets"
import "../common"
import "../services" as Services

PanelWindow {
    id: root

    property bool isTop: true
    property int barSize: 32
    readonly property color barColor: Theme.background
    readonly property color textColor: Theme.text
    readonly property color outlineColor: Theme.outline

    implicitHeight: barSize

    anchors {
        top: root.isTop
        bottom: !root.isTop
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Auto

    Rectangle {
        id: barContent
        anchors.fill: parent
        color: barColor
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowVerticalOffset: root.isTop ? 4 : -4
            shadowBlur: 0.5
            shadowColor: "#90000000"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            FocusedWindow {
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Media {
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Tray {
                Layout.preferredWidth: 80
                Layout.alignment: Qt.AlignVCenter
            }
            Privacy {
                Layout.preferredWidth: 24
                Layout.alignment: Qt.AlignVCenter
            }
            CpuWidget {
                Layout.preferredWidth: 52
                Layout.alignment: Qt.AlignVCenter
            }
            RamWidget {
                Layout.preferredWidth: 52
                Layout.alignment: Qt.AlignVCenter
            }
            NetworkWidget {
                Layout.preferredWidth: 60
                Layout.alignment: Qt.AlignVCenter
            }
            Battery {
                Layout.preferredWidth: 52
                Layout.alignment: Qt.AlignVCenter
            }
            Clock {
                Layout.preferredWidth: 130
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
