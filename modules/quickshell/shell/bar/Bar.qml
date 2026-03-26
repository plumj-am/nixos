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
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0

                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Media {
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            FocusedWindow {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.minimumWidth: implicitWidth
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Tray {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Privacy {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Separator { Layout.alignment: Qt.AlignVCenter }
                    CpuWidget {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    RamWidget {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    DiskWidget {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    NetworkWidget {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    GpuWidget {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Battery {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Separator { Layout.alignment: Qt.AlignVCenter }
                    NotificationWidget {
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Clock {
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
