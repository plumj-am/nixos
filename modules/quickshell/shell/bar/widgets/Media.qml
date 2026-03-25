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
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: Mpris.isPlaying ? "\uf04b" : "\uf04c"
            font.family: "Hasklug Nerd Font Mono"
            font.pixelSize: 12
            color: Theme.foreground
            visible: Mpris.hasPlayer
        }

        Text {
            Layout.maximumWidth: 200
            text: Mpris.trackTitle ? Mpris.trackTitle : "No track"
            font.family: Theme.font.sans.name
            font.pixelSize: 12
            color: Theme.foreground
            elide: Text.ElideRight
            visible: Mpris.hasPlayer
        }

        Text {
            text: Mpris.trackArtist ? " - " + Mpris.trackArtist : ""
            font.family: Theme.font.sans.name
            font.pixelSize: 12
            color: Theme.textMuted
            elide: Text.ElideRight
            visible: Mpris.hasPlayer && Mpris.trackArtist
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Mpris.playPause()
    }
}
