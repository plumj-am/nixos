import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../common"

Item {
    id: root

    implicitHeight: 24
    implicitWidth: trayRow.implicitWidth + 8

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayItemDelegate

                property SystemTrayItem trayItem: modelData

                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: Theme.radius.small
                color: trayMouseArea.containsMouse ? Theme.surface : "transparent"

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: {
                        let icon = trayItem?.icon ?? ""
                        if (icon.includes("?path=")) {
                            const split = icon.split("?path=")
                            if (split.length === 2) {
                                return "file://" + split[1] + "/" + split[0]
                            }
                        }
                        if (icon.startsWith("/") && !icon.startsWith("file://")) {
                            return "file://" + icon
                        }
                        return icon
                    }
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !trayIcon.visible
                    text: {
                        const itemId = trayItem?.id ?? ""
                        return itemId ? itemId.charAt(0).toUpperCase() : "?"
                    }
                    font.pixelSize: 10
                    color: Theme.foreground
                }

                MouseArea {
                    id: trayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (!trayItem) return
                        if (mouse.button === Qt.LeftButton) {
                            if (!trayItem.onlyMenu) {
                                trayItem.activate()
                            } else if (trayItem.hasMenu) {
                                trayMenu.open()
                            }
                        } else if (mouse.button === Qt.RightButton && trayItem.hasMenu) {
                            trayMenu.open()
                        }
                    }
                }

                QsMenuAnchor {
                    id: trayMenu
                    menu: trayItem?.menu
                    anchor.item: trayItemDelegate
                }
            }
        }
    }
}
