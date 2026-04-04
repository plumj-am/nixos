import QtQuick
import QtQuick.Layouts
import "../../common" as Common

Item {
    id: root

    implicitWidth: 300
    implicitHeight: 40

    property var node: null
    readonly property real volume: 0.0
    readonly property bool muted: false
    readonly property string iconSource: ""
    readonly property string label: ""

    RowLayout {
        spacing: 4

        Text {
            text: node ? `${Math.round(node.volume * 100)}%` : ""
            font.family: Common.Theme.font.icons.family
            font.pixelSize: 13
            color: node && node.audio && node.audio.muted ? Common.Theme.accent : Common.Theme.foreground
        }
    }
}
