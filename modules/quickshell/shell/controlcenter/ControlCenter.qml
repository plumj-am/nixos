import QtQuick
import QtQuick.Layouts
import "../../common" as Common

Item {
    id: root

    property bool open: false

    implicitWidth: 360
    implicitHeight: open ? contentColumn.implicitHeight + 24 : 0
    visible: implicitHeight > 0

    Behavior on implicitHeight {
        Common.NAnim {}
    }

    Common.Corner {
        location: Qt.TopRightCorner
        extensionSide: Qt.Horizontal
        radius: root.open ? Common.Config.data.shell.cornerRadius : 0
        color: Common.Theme.background
    }

    Common.Corner {
        location: Qt.BottomLeftCorner
        extensionSide: Qt.Vertical
        radius: root.open ? Common.Config.data.shell.cornerRadius : 0
        color: Common.Theme.background
    }

    Rectangle {
        anchors.fill: parent
        color: Common.Theme.background
        radius: 0
        bottomRightRadius: Common.Theme.radius.big
        clip: true

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Text {
                text: "Control Center"
                font.family: Common.Theme.font.sans.family
                font.pixelSize: Common.Theme.font.sans.size
                font.bold: true
                color: Common.Theme.foreground
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Common.Theme.outline
            }

            Text {
                text: "Coming soon..."
                font.family: Common.Theme.font.sans.family
                font.pixelSize: Common.Theme.font.sans.size
                color: Common.Theme.textMuted
            }
        }
    }
}
