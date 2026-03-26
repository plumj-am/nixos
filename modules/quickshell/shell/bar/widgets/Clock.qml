import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../common"

Item {
    id: root

    property real size: 24

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    implicitWidth: row.width + 8
    implicitHeight: size

    RowLayout {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        Text {
            visible: Config.data.clock?.date?.enabled !== false
            text: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
            font.family: Theme.font.sans.family
            font.pixelSize: Theme.font.sans.size
            color: Theme.textMuted
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.family: Theme.font.sans.family
            font.pixelSize: Theme.font.sans.size
            font.bold: true
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
