import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../common/widgets"

Item {
    id: root

    property string label: ""
    property string valueText: ""
    property var popupLines: []

    implicitWidth: row.width + 8
    implicitHeight: 24

    RowLayout {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        height: 20

        Text {
            text: root.label
            font.family: Config.data.theme.fontMono.family
            font.pixelSize: Config.data.theme.fontMono.size
            font.bold: true
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: root.valueText
            font.family: Config.data.theme.fontMono.family
            font.pixelSize: Config.data.theme.fontMono.size
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    HoverPopup {
        anchors.centerIn: root
        hoverTarget: root
        anchorPosition: Types.stringToPosition(Config.data.bar.position)
        contentComponent: Component {
            ColumnLayout {
                spacing: 4
                Repeater {
                    model: root.popupLines
                    delegate: Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.text
                        font.family: modelData.mono ? Config.data.theme.fontMono.family : Config.data.theme.font.family
                        font.pixelSize: modelData.mono ? Config.data.theme.fontMono.size : Config.data.theme.font.size
                        font.bold: modelData.bold || false
                        color: modelData.muted ? Theme.textMuted : Theme.foreground
                    }
                }
            }
        }
    }
}
