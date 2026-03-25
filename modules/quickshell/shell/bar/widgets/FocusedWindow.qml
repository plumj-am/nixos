import QtQuick
import "../../common"
import "../../services"

Row {
    id: root
    spacing: 4

    property real implicitWidth: 200
    property real implicitHeight: 20

    Image {
        anchors.verticalCenter: parent.verticalCenter
        source: Niri.focusedWindow?.iconPath ? "file://" + Niri.focusedWindow?.iconPath : ""
        sourceSize.width: 20
        sourceSize.height: 15
        visible: Niri.focusedWindow?.iconPath !== ""
        smooth: true
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 15
        height: 15
        color: "#CCC"
        visible: Niri.focusedWindow?.iconPath === ""
        radius: 12
    }

    Text {
        width: 200
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        text: Niri.focusedWindow?.title ?? ""
        font.family: Config.data.theme.font.family
        font.pixelSize: Config.data.theme.font.size
        color: Config.data.theme.colors.text
    }
}
