import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "widgets"
import "../common"
import "../services" as Services

Item {
    id: root

    property var screen
    property int barSize: Config.data.bar?.size ?? 30
    property string barPosition: Config.data.bar?.position ?? "top"
    property color barColor: Theme.background

    readonly property bool isTop: barPosition === "top"

    WlrLayershell {
        id: shadowWindow
        screen: root.screen
        layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Ignore
        anchors: barWindow.anchors
        implicitHeight: barSize + 10
        color: "transparent"

        Rectangle {
            anchors {
                top: root.isTop ? parent.top : undefined
                bottom: root.isTop ? undefined : parent.bottom
                left: parent.left
                right: parent.right
            }
            height: barSize
            color: barColor
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowVerticalOffset: root.isTop ? 4 : -4
                shadowBlur: 0.5
                shadowColor: "#90000000"
            }
        }
    }

    PanelWindow {
        id: barWindow
        screen: root.screen
        implicitHeight: barSize
        color: "transparent"

        anchors {
            top: root.isTop
            bottom: root.isTop ? undefined : true
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
}
