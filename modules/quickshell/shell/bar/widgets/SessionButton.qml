import QtQuick
import "../../common"

Item {
    id: root

    implicitWidth: 24
    implicitHeight: 24

    signal clicked()

    Text {
        anchors.centerIn: parent
        text: "\uf011"
        font.family: Theme.font.mono.family
        font.pixelSize: Theme.font.sans.size
        color: mouseArea.containsMouse ? Theme.accent : Theme.foreground
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
