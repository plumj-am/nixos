import QtQuick
import QtQuick.Layouts
import "../../common" as Common

Item {
    id: root

    property bool open: false

    implicitWidth: 360
    implicitHeight: open ? contentLoader.implicitHeight + 24 : 0
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

        Loader {
            id: contentLoader
            active: root.open
            asynchronous: true
            anchors.fill: parent
            anchors.margins: 12

            sourceComponent: ColumnLayout {
                spacing: 12

                // Audio section
                AudioSlider {
                    Layout.fillWidth: true
                    node: Pipewire.defaultAudioSink
                    icon: node && node.audio && node.audio.muted ? "\uf6a9" : "\uf028"
                    label: "Output"
                }

                AudioSlider {
                    Layout.fillWidth: true
                    node: Pipewire.defaultAudioSource
                    icon: "\uf130"
                    label: "Input"
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Common.Theme.outline
                }

                // Brightness
                BrightnessSlider {
                    Layout.fillWidth: true
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Common.Theme.outline
                }

                // Bluetooth
                BluetoothToggle {
                    Layout.fillWidth: true
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Common.Theme.outline
                }

                // Network
                NetworkInfo {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
