import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../common" as Common

Item {
    id: root

    property bool open: false

    implicitWidth: open ? 80 : 0
    implicitHeight: parent.height * 0.5
    visible: implicitWidth > 0

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
        rightMargin: Common.Config.data.shell.enableOuterBorder ? Common.Config.data.shell.outerBorderSize - 0.05 : 0
    }

    Behavior on implicitWidth {
        Common.NAnim {}
    }

    Common.Corner {
        location: Qt.TopRightCorner
        extensionSide: Qt.Vertical
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
        radius: 0
        topLeftRadius: Common.Theme.radius.big
        bottomLeftRadius: Common.Theme.radius.big
        color: Common.Theme.background
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Repeater {
                model: [
                    {
                        "icon": "\uf011",
                        "name": "Shutdown",
                        "action": "shutdown"
                    },
                    {
                        "icon": "\uf2f1",
                        "name": "Reboot",
                        "action": "reboot"
                    },
                    {
                        "icon": "\uf236",
                        "name": "Suspend",
                        "action": "suspend"
                    },
                    {
                        "icon": "\uf2f5",
                        "name": "Logout",
                        "action": "logout"
                    },
                    {
                        "icon": "\uf023",
                        "name": "Lock",
                        "action": "lock"
                    }
                ]

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 70
                    color: mouseArea.containsMouse ? Qt.alpha(Common.Theme.accent, 0.2) : "transparent"
                    radius: Common.Theme.radius.small

                    property real animProgress: root.open ? 1 : 0

                    transform: Translate {
                        x: (1 - animProgress) * 120
                    }

                    Behavior on animProgress {
                        Common.NAnim {
                            duration: 200
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: Common.Theme.font.icons.family
                        font.pixelSize: 22
                        color: mouseArea.pressed ? Common.Theme.accent : Common.Theme.foreground
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.executeAction(modelData.action)
                    }
                }
            }
        }
    }

    function executeAction(action) {
        var cmds = {
            "shutdown": ["systemctl", "poweroff"],
            "reboot": ["systemctl", "reboot"],
            "suspend": ["systemctl", "suspend"],
            "hibernate": ["systemctl", "hibernate"],
            "logout": ["niri", "msg", "action", "quit"]
        };
        if (action === "lock") {
            Quickshell.execDetached({ command: ["qs", "ipc", "call", "lock", "toggle"] });
        } else {
            var cmd = cmds[action];
            if (cmd)
                Quickshell.execDetached({ command: cmd });
        }
    }
}
