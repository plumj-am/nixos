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
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 4

            Item { Layout.preferredWidth: 4 }
            
            FocusedWindow {
                Layout.fillWidth: true
                Layout.maximumWidth: 400
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 6
                Media {}
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 6
                Tray {}
                Privacy { Layout.preferredWidth: 24 }
                CpuWidget { Layout.preferredWidth: 48 }
                RamWidget { Layout.preferredWidth: 48 }
                NetworkWidget { Layout.preferredWidth: 48 }
                Battery { Layout.preferredWidth: 48 }
                Clock { Layout.preferredWidth: 120 }
            }

            Item { Layout.preferredWidth: 4 }
        }
        }
    }
