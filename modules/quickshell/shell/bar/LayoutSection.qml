import QtQuick
import QtQuick.Layouts
import Quickshell
import "../common"

RowLayout {
    id: root

    property string section: "left"
    property var widgetComponents: ({})
    spacing: Config.data.bar[section]?.spacing ?? Theme.margin.small

    Repeater {
        model: Config.data.bar[section]?.widgets ?? []

        delegate: Loader {
            id: widgetLoader
            Layout.fillHeight: true
            sourceComponent: widgetComponents[modelData]

            onLoaded: {
                if (!item) return
                if (item.implicitWidth !== undefined) {
                    Layout.preferredWidth = item.implicitWidth
                }
            }
        }
    }
}
