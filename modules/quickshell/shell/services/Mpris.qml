pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property var activePlayer: null
    readonly property bool hasPlayer: activePlayer !== null
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackArtUrl: ""
    property bool isPlaying: false

    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 1
    readonly property string identity: activePlayer?.identity ?? ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateActivePlayer()
    }

    function updateActivePlayer() {
        const players = Mpris.players.values
        if (players.length > 0) {
            const playing = players.find(p => p.isPlaying)
            activePlayer = playing ?? players[0]
            if (activePlayer) {
                trackTitle = activePlayer.trackTitle ?? ""
                trackArtist = activePlayer.trackArtist ?? ""
                trackArtUrl = activePlayer.trackArtUrl ?? ""
                isPlaying = activePlayer.isPlaying ?? false
            }
        } else {
            activePlayer = null
            trackTitle = ""
            trackArtist = ""
            trackArtUrl = ""
            isPlaying = false
        }
    }

    Component.onCompleted: updateActivePlayer()

    function playPause() {
        if (activePlayer) {
            if (activePlayer.isPlaying) {
                activePlayer.pause()
            } else {
                activePlayer.play()
            }
        }
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next()
        }
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous()
        }
    }

    function setPosition(pos) {
        if (activePlayer) {
            activePlayer.position = pos
        }
    }

    function formatTime(seconds) {
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
}
