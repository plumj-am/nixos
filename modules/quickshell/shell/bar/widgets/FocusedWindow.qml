import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../services"

RowLayout {
    id: root
    spacing: 2

    Image {
        source: Niri.focusedWindow?.iconPath ? "file://" + Niri.focusedWindow?.iconPath : ""
        sourceSize.width: 16
        sourceSize.height: 16
        visible: Niri.focusedWindow?.iconPath !== ""
        smooth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        width: 16
        height: 16
        color: Theme.textMuted
        visible: Niri.focusedWindow?.iconPath === ""
        radius: 4
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        Layout.maximumWidth: 300
        elide: Text.ElideRight
        text: Niri.focusedWindow?.title ?? ""
        font.family: Theme.font.sans.name
        font.pixelSize: 13
        color: Theme.text
        Layout.alignment: Qt.AlignVCenter
    }
}
