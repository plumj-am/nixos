import QtQuick
import QtQuick.Layouts
import "../common" as Common
import "."

Item {
    id: root

    property bool open: false
    property bool popupMode: false

    implicitWidth: 320
    implicitHeight: open ? contentLoader.implicitHeight + 24 : 0
    visible: implicitHeight > 0

    Behavior on implicitHeight {
        Common.NAnim {}
    }

    Rectangle {
        anchors.fill: parent
        color: Common.Theme.background
        radius: Common.Theme.radius.small
        clip: true

        Loader {
            id: contentLoader
            active: root.open
            asynchronous: true
            anchors.fill: parent
            anchors.margins: 12
            sourceComponent: NotificationPopupContent {
                popupMode: root.popupMode
            }
        }
    }

    Common.Border {
        anchors.fill: parent
    }
}
