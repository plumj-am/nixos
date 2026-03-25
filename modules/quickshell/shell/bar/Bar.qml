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

    property var screen
    property bool isTop: true
    property int barSize: 32
    readonly property color barColor: Theme.background
    readonly property color textColor: Theme.text
    readonly property color outlineColor: Theme.outline

    readonly property bool isVertical: root.isTop

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
        height: barSize
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
                anchors.leftMargin: Theme.margin.small
                anchors.rightMargin: Theme.margin.small
                spacing: Theme.margin.small

                Row {
                    spacing: 6
                    FocusedWindow {}
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
                    Privacy {}
                    CpuWidget {}
                    RamWidget {}
                    NetworkWidget {}
                    Battery {}
                    Clock {}
                }
            }
        }
    }
