import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../services"

RowLayout {
    id: root
    spacing: 2

    Image {
        id: windowIcon
        source: Niri.focusedWindow?.iconPath ? "file://" + Niri.focusedWindow?.iconPath : ""
        sourceSize.width: 16
        sourceSize.height: 16
        visible: Niri.focusedWindow?.iconPath !== "" && status === Image.Ready
        smooth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        Layout.maximumWidth: 300
        elide: Text.ElideRight
        text: Niri.focusedWindow?.title ?? ""
        font.family: Theme.font.sans.family
        font.pixelSize: 13
        color: Theme.text
        Layout.alignment: Qt.AlignVCenter
    }
}
