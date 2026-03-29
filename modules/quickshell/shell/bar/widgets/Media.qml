import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../services"

Item {
    id: root

    property bool drawerOpen: false

    implicitHeight: 24
    implicitWidth: mediaRow.implicitWidth + 8
    visible: Mpris.hasPlayer

    signal clicked()

    RowLayout {
        id: mediaRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 6

        Text {
            text: Mpris.isPlaying ? "\uf04b" : "\uf04c"
            font.family: Theme.font.icons.family
            font.pixelSize: 12
            color: mouseArea.containsMouse || root.drawerOpen ? Theme.accent : Theme.foreground
            visible: Mpris.hasPlayer
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.maximumWidth: 200
            text: Mpris.trackTitle ? Mpris.trackTitle : "No track"
            font.family: Theme.font.sans.family
            font.pixelSize: 12
            color: mouseArea.containsMouse || root.drawerOpen ? Theme.accent : Theme.foreground
            elide: Text.ElideRight
            visible: Mpris.hasPlayer
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: Mpris.trackArtist ? " - " + Mpris.trackArtist : ""
            font.family: Theme.font.sans.family
            font.pixelSize: 12
            color: Theme.textMuted
            elide: Text.ElideRight
            visible: Mpris.hasPlayer && Mpris.trackArtist
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
