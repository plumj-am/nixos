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
    property int barSize: 28
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

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
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
                Layout.alignment: Qt.AlignVCenter
            }
            Privacy {
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "|"
                color: Theme.textMuted
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }
            CpuWidget {
                Layout.alignment: Qt.AlignVCenter
            }
            RamWidget {
                Layout.alignment: Qt.AlignVCenter
            }
            NetworkWidget {
                Layout.alignment: Qt.AlignVCenter
            }
            Battery {
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "|"
                color: Theme.textMuted
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }
            Clock {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
