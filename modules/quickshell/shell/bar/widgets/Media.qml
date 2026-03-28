import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../common"
import "../../common/widgets"
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
            font.family: Theme.font.mono.family
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
        id: clickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Mpris.playPause()
    }

    PersistentPopup {
        anchors.centerIn: root
        hoverTarget: root
        anchorPosition: Types.stringToPosition(Config.data.bar.position)
        corner: Types.cornerTopLeft
        fillRemainingWidth: true
        contentComponent: Component {
            ColumnLayout {
                id: popupContent
                spacing: 12
                Layout.fillWidth: true

                RowLayout {
                    spacing: 12

                    Rectangle {
                        id: albumArt
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 80
                        color: Theme.surface
                        radius: Theme.radius.normal

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
                            font.family: Theme.font.mono.family
                            font.pixelSize: 28
                            color: Theme.textMuted
                            visible: !albumArtImage.visible
                        }
                    }

                    ColumnLayout {
                        Layout.maximumWidth: 180
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: Mpris.trackTitle || "No track"
                            font.family: Theme.font.sans.family
                            font.pixelSize: Theme.font.sans.size
                            font.bold: true
                            color: Theme.foreground
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Mpris.trackArtist || "Unknown artist"
                            font.family: Theme.font.sans.family
                            font.pixelSize: Theme.font.sans.size - 2
                            color: Theme.textMuted
                            elide: Text.ElideRight
                        }

                        Text {
                            text: Mpris.identity
                            font.family: Theme.font.mono.family
                            font.pixelSize: Theme.font.mono.size - 2
                            color: Theme.textMuted
                            visible: Mpris.identity !== ""
                        }
                    }
                }

                ColumnLayout {
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        color: Theme.surface
                        radius: 2

                        Rectangle {
                            width: parent.width * Math.min(1, Mpris.position / Math.max(1, Mpris.length))
                            height: parent.height
                            color: Theme.primary
                            radius: 2
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: Mpris.formatTime(Mpris.position)
                            font.family: Theme.font.mono.family
                            font.pixelSize: Theme.font.mono.size - 2
                            color: Theme.textMuted
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: Mpris.formatTime(Mpris.length)
                            font.family: Theme.font.mono.family
                            font.pixelSize: Theme.font.mono.size - 2
                            color: Theme.textMuted
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Text {
                        text: "\uf048"
                        font.family: Theme.font.mono.family
                        font.pixelSize: 16
                        color: Mpris.canGoPrevious ? Theme.foreground : Theme.textMuted
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Mpris.canGoPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (Mpris.canGoPrevious)
                                Mpris.previous()
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: playPauseHover.hovered ? Theme.primary : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: Mpris.isPlaying ? "\uf04c" : "\uf04b"
                            font.family: Theme.font.mono.family
                            font.pixelSize: 14
                            color: Theme.background
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
                        font.family: Theme.font.mono.family
                        font.pixelSize: 16
                        color: Mpris.canGoNext ? Theme.foreground : Theme.textMuted
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Mpris.canGoNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (Mpris.canGoNext)
                                Mpris.next()
                        }
                    }
                }
            }
        }
    }
}
