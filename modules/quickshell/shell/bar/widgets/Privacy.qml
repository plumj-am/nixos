import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../common"

Item {
    id: root

    implicitHeight: 24
    implicitWidth: privacyRow.implicitWidth + 8

    property bool microphoneActive: micTracker.linkGroups.length > 0
    property bool cameraActive: false

    PwNodeLinkTracker {
        id: micTracker
        node: Pipewire.defaultAudioSource
    }

    RowLayout {
        id: privacyRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 4

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: Theme.radius.small
            color: root.microphoneActive ? Theme.error : Theme.foreground2
            visible: root.microphoneActive
        }

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: Theme.radius.small
            color: root.cameraActive ? Theme.error : Theme.foreground2
            visible: root.cameraActive
        }
    }

    visible: root.microphoneActive || root.cameraActive
}
