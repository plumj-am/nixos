import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../common"

Item {
    id: root

    implicitHeight: 24
    implicitWidth: privacyRow.implicitWidth + 8

    property bool microphoneActive: false
    property bool cameraActive: false

    RowLayout {
        id: privacyRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 4

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: Theme.radius.small
            color: microphoneActive ? Theme.error : Theme.foreground2
            visible: microphoneActive
        }

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: Theme.radius.small
            color: cameraActive ? Theme.error : Theme.foreground2
            visible: cameraActive
        }
    }

    visible: microphoneActive || cameraActive
}
