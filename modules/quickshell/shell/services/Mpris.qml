pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property var activePlayer: null
    readonly property bool hasPlayer: activePlayer !== null
    readonly property string trackTitle: activePlayer?.trackTitle ?? ""
    readonly property string trackArtist: activePlayer?.trackArtist ?? ""
    readonly property string trackArtUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing

    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 1
    property bool positionTrackingEnabled: false
    readonly property string identity: activePlayer?.identity ?? ""

    // Keep position updating while playing
    property Timer _posUpdater: Timer {
        running: root.isPlaying && root.positionTrackingEnabled
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.activePlayer) root.activePlayer.positionChanged()
        }
    }

    function _updateActivePlayer() {
        const players = Mpris.players.values
        if (players.length > 0) {
            const playing = players.find(p => p.playbackState === MprisPlaybackState.Playing)
            activePlayer = playing ?? players[0]
        } else {
            activePlayer = null
        }
    }

    Component.onCompleted: _updateActivePlayer()

    Connections {
        target: Mpris.players
        function onObjectInsertedPost() { root._updateActivePlayer() }
        function onObjectRemovedPost() { root._updateActivePlayer() }
    }

    function playPause() {
        if (activePlayer) {
            if (activePlayer.playbackState === MprisPlaybackState.Playing) {
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

    function formatTime(seconds) {
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
}
