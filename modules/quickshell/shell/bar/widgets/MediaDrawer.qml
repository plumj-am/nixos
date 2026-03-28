import QtQuick
import QtQuick.Layouts
import "../../common" as Common
import "../../services"

Item {
    id: root

    property bool open: false

    implicitWidth: 340
    implicitHeight: open ? contentColumn.implicitHeight + 24 : 0
    visible: implicitHeight > 0
    clip: true

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

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    color: Common.Theme.surface
                    radius: Common.Theme.radius.normal

                    Image {
                        id: albumArtImage
                        anchors.fill: parent
                        anchors.margins: 2
                        source: Mpris.trackArtUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf001"
                        font.family: Common.Theme.font.mono.family
                        font.pixelSize: 28
                        color: Common.Theme.textMuted
                        visible: !albumArtImage.visible
                    }
                }

                ColumnLayout {
                    Layout.maximumWidth: 180
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: Mpris.trackTitle || "No track"
                        font.family: Common.Theme.font.sans.family
                        font.pixelSize: Common.Theme.font.sans.size
                        font.bold: true
                        color: Common.Theme.foreground
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Mpris.trackArtist || "Unknown artist"
                        font.family: Common.Theme.font.sans.family
                        font.pixelSize: Common.Theme.font.sans.size - 2
                        color: Common.Theme.textMuted
                        elide: Text.ElideRight
                    }

                    Text {
                        text: Mpris.identity
                        font.family: Common.Theme.font.mono.family
                        font.pixelSize: Common.Theme.font.mono.size - 2
                        color: Common.Theme.textMuted
                        visible: Mpris.identity !== ""
                    }
                }
            }

            ColumnLayout {
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    color: Common.Theme.surface
                    radius: 2

                    Rectangle {
                        width: parent.width * Math.min(1, Mpris.position / Math.max(1, Mpris.length))
                        height: parent.height
                        color: Common.Theme.primary
                        radius: 2
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: Mpris.formatTime(Mpris.position)
                        font.family: Common.Theme.font.mono.family
                        font.pixelSize: Common.Theme.font.mono.size - 2
                        color: Common.Theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: Mpris.formatTime(Mpris.length)
                        font.family: Common.Theme.font.mono.family
                        font.pixelSize: Common.Theme.font.mono.size - 2
                        color: Common.Theme.textMuted
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Text {
                    text: "\uf048"
                    font.family: Common.Theme.font.mono.family
                    font.pixelSize: 16
                    color: Mpris.canGoPrevious ? Common.Theme.foreground : Common.Theme.textMuted
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Mpris.canGoPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (Mpris.canGoPrevious) Mpris.previous()
                    }
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: playPauseHover.hovered ? Common.Theme.primary : Common.Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: Mpris.isPlaying ? "\uf04c" : "\uf04b"
                        font.family: Common.Theme.font.mono.family
                        font.pixelSize: 14
                        color: Common.Theme.background
                    }

                    HoverHandler {
                        id: playPauseHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: Mpris.playPause()
                    }
                }

                Text {
                    text: "\uf051"
                    font.family: Common.Theme.font.mono.family
                    font.pixelSize: 16
                    color: Mpris.canGoNext ? Common.Theme.foreground : Common.Theme.textMuted
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Mpris.canGoNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (Mpris.canGoNext) Mpris.next()
                    }
                }
            }
        }
    }
}
