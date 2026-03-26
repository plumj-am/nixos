import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../common" as Common

Rectangle {
    id: root

    property var notification: null
    property int notificationIndex: -1
    property bool showActions: true
    property bool showDismiss: true
    property int maxWidth: 420

    signal dismissed()
    signal actionTriggered(var action)

    implicitWidth: contentLayout.implicitWidth + Common.Theme.padding.normal * 2
    implicitHeight: contentLayout.implicitHeight + Common.Theme.padding.normal * 2
    width: Math.max(300, Math.min(implicitWidth, maxWidth))
    height: implicitHeight
    color: Common.Theme.background
    radius: Common.Theme.radius.normal
    border.width: 1
    border.color: urgencyColor

    readonly property color urgencyColor: {
        if (!notification) return Common.Theme.outline
        switch (notification.urgency) {
            case 2: return Common.Theme.error
            case 1: return Common.Theme.warning
            default: return Common.Theme.outline
        }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: Common.Theme.padding.normal
        spacing: Common.Theme.margin.normal

        IconImage {
            id: appIcon
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            implicitSize: 32
            source: {
                if (!notification) return ""
                const icon = notification.appIcon || notification.desktopEntry || "dialog-information"
                return Quickshell.iconPath(icon, "dialog-information")
            }
            asynchronous: true
            visible: status === Image.Ready
        }

        Image {
            id: notifImage
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            source: notification?.image || ""
            fillMode: Image.PreserveAspectCrop
            visible: notification?.image !== undefined && notification?.image !== "" && status === Image.Ready
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Theme.margin.small

                Text {
                    text: notification?.appName || "Unknown"
                    color: Common.Theme.textMuted
                    font.family: Common.Theme.font.sans.name
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: formatTime(notification?.time)
                    color: Common.Theme.textMuted
                    font.family: Common.Theme.font.sans.name
                    font.pixelSize: 10
                    visible: notification?.time !== undefined && notification?.time !== 0
                }
            }

            Text {
                text: notification?.summary || ""
                color: Common.Theme.text
                font.family: Common.Theme.font.sans.name
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: text !== ""
            }

            Text {
                text: notification?.body || ""
                color: Common.Theme.foreground
                font.family: Common.Theme.font.sans.name
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                Layout.fillWidth: true
                visible: text !== ""
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Theme.margin.small
                visible: root.showActions && notification?.actions !== undefined && notification?.actions?.length > 0

                Repeater {
                    model: notification?.actions || []

                    Rectangle {
                        Layout.preferredHeight: 24
                        implicitWidth: actionText.implicitWidth + Common.Theme.padding.normal * 2
                        color: actionMouseArea.containsMouse ? Common.Theme.surfaceContainer : Common.Theme.surface
                        radius: Common.Theme.radius.small

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text || modelData.identifier || "Action"
                            color: Common.Theme.accent
                            font.family: Common.Theme.font.sans.name
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: actionMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionTriggered(modelData)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            color: dismissMouseArea.containsMouse ? Common.Theme.surfaceContainer : "transparent"
            radius: Common.Theme.radius.small
            visible: root.showDismiss

            Text {
                anchors.centerIn: parent
                text: "×"
                color: Common.Theme.textMuted
                font.family: Common.Theme.font.sans.name
                font.pixelSize: 14
            }

            MouseArea {
                id: dismissMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissed()
            }
        }
    }

    function formatTime(timestamp) {
        if (!timestamp) return ""
        const date = new Date(timestamp)
        const now = new Date()
        const diff = (now - date) / 1000

        if (diff < 60) return "now"
        if (diff < 3600) return Math.floor(diff / 60) + "m"
        if (diff < 86400) return Math.floor(diff / 3600) + "h"
        return date.toLocaleDateString(Qt.locale(), "MMM d")
    }
}
