import QtQuick
import QtQuick.Layouts
import "../common" as Common
import "."

Item {
    id: root

    property bool open: false

    implicitWidth: 320
    implicitHeight: open ? contentLoader.implicitHeight + 24 : 0
    visible: implicitHeight > 0

    Behavior on implicitHeight {
        Common.NAnim {}
    }

    Common.Corner {
        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
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
        color: Common.Theme.background
        radius: 0
        bottomLeftRadius: Common.Theme.radius.big

        Loader {
            id: contentLoader
            active: root.open
            asynchronous: true
            anchors.fill: parent
            anchors.margins: 12
            sourceComponent: NotificationPopupContent {}
        }
    }
}
