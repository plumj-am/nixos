import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../services"

RowLayout {
    id: root
    spacing: 4

    property real implicitWidth: 200
    property real implicitHeight: 20

    Image {
        source: Niri.focusedWindow?.iconPath ? "file://" + Niri.focusedWindow?.iconPath : ""
        sourceSize.width: 20
        sourceSize.height: 15
        visible: Niri.focusedWindow?.iconPath !== ""
        smooth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        width: 15
        height: 15
        color: "#CCC"
        visible: Niri.focusedWindow?.iconPath === ""
        radius: 12
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        Layout.maximumWidth: 200
        elide: Text.ElideRight
        text: Niri.focusedWindow?.title ?? ""
        font.family: Config.data.theme.font.family
        font.pixelSize: Config.data.theme.font.size
        color: Config.data.theme.colors.text
        Layout.alignment: Qt.AlignVCenter
    }
}
