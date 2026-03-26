import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../common"
import "../../services"

Item {
    id: root

    implicitHeight: 24
    implicitWidth: mediaRow.implicitWidth + 8
    visible: Mpris.hasPlayer

    RowLayout {
        id: mediaRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 6

        Text {
            text: Mpris.isPlaying ? "\uf04b" : "\uf04c"
            font.family: "Hasklug Nerd Font Mono"
            font.pixelSize: 12
            color: Theme.foreground
            visible: Mpris.hasPlayer
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.maximumWidth: 200
            text: Mpris.trackTitle ? Mpris.trackTitle : "No track"
            font.family: Theme.font.sans.family
            font.pixelSize: 12
            color: Theme.foreground
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
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Mpris.playPause()
    }
}
