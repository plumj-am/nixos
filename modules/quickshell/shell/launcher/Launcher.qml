import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common" as Common

PanelWindow {
    id: root

    readonly property string fallbackIcon: Quickshell.iconPath("dialog-question", true)

    property bool isOpen: false
    property string searchText: ""
    property int selectedIndex: 0
    property var allApps: []
    property var screen: null
    property Timer searchDebounce: Timer {
        interval: 50
        onTriggered: root.filterApps()
    }

    ListModel {
        id: appModel
    }

    visible: isOpen || launcherClip.implicitHeight > 0
    color: "transparent"
    implicitHeight: 800

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    readonly property int barHeight: Common.Config.data.bar.size
    readonly property int launcherWidth: 500
    readonly property int launcherHeight: 440
    readonly property int itemHeight: 48

    Component.onCompleted: loadApps()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            loadApps();
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchText = "";
            selectedIndex = 0;
            searchField.forceActiveFocus();
        }
    }

    function loadApps() {
        var apps = [];
        var entries = DesktopEntries.applications.values;
        for (var i = 0; i < entries.length; i++) {
            var app = entries[i];
            if (!app.noDisplay && !app.hidden) {
                var iconName = app.icon || "application-x-executable";
                apps.push({
                    name: app.name || "Unknown",
                    description: app.genericName || app.comment || "",
                    iconPath: Quickshell.iconPath(iconName, true) || root.fallbackIcon,
                    command: app.command || [],
                    app: app
                });
            }
        }
        apps.sort(function (a, b) {
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
        });
        allApps = apps;
        filterApps();
    }

    function filterApps() {
        var results;
        if (!searchText || searchText.trim() === "") {
            results = allApps.slice(0, 50);
        } else {
            var query = searchText.toLowerCase();
            results = [];
            for (var i = 0; i < allApps.length; i++) {
                var app = allApps[i];
                var name = (app.name || "").toLowerCase();
                var desc = (app.description || "").toLowerCase();
                if (name.indexOf(query) !== -1 || desc.indexOf(query) !== -1) {
                    results.push(app);
                }
                if (results.length >= 50)
                    break;
            }
        }

        appModel.clear();
        for (var j = 0; j < results.length; j++) {
            appModel.append(results[j]);
        }
        selectedIndex = 0;
    }

    function launchSelected() {
        if (appModel.count > 0 && selectedIndex >= 0 && selectedIndex < appModel.count) {
            var entry = appModel.get(selectedIndex);
            var app = entry.app;
            if (app.execute) {
                app.execute();
            } else if (app.command && app.command.length > 0) {
                Qt.callLater(function () {
                    Quickshell.execDetached(app.command);
                });
            }
            isOpen = false;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.isOpen = false
    }

    Item {
        id: launcherClip
        anchors.horizontalCenter: parent.horizontalCenter
        y: barHeight
        width: launcherWidth
        implicitHeight: root.isOpen ? launcherHeight : 0
        visible: implicitHeight > 0

        Behavior on implicitHeight {
            Common.NAnim {}
        }

        clip: true

        Item {
            id: launcherBody
            width: launcherWidth
            height: launcherHeight

            // Body rectangle
            Rectangle {
                anchors.fill: parent
                color: Common.Theme.background
                radius: 0
                bottomLeftRadius: Common.Theme.radius.big
                bottomRightRadius: Common.Theme.radius.big
                clip: true

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search applications..."
                        onTextChanged: {
                            root.searchText = text;
                            root.searchDebounce.restart();
                        }
                        color: Common.Theme.text
                        placeholderTextColor: Common.Theme.textMuted
                        font.family: Common.Theme.font.sans.family
                        font.pixelSize: 14
                        background: Rectangle {
                            color: Common.Theme.background2
                            radius: Common.Theme.radius.small
                            border.color: searchField.activeFocus ? Common.Theme.background : Common.Theme.outline
                        }

                        Keys.onEscapePressed: root.isOpen = false
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
                        Keys.onUpPressed: {
                            if (root.selectedIndex > 0) {
                                root.selectedIndex--;
                            }
                        }
                        Keys.onDownPressed: {
                            if (root.selectedIndex < appModel.count - 1) {
                                root.selectedIndex++;
                            }
                        }
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier)) {
                                event.accepted = true;
                                var cursorPos = searchField.cursorPosition;
                                var text = searchField.text;
                                if (cursorPos === 0)
                                    return;
                                var start = cursorPos - 1;
                                while (start > 0 && text.charAt(start - 1) !== ' ') {
                                    start--;
                                }
                                searchField.text = text.substring(0, start) + text.substring(cursorPos);
                                searchField.cursorPosition = start;
                            }
                        }
                    }

                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: appModel
                        clip: true
                        currentIndex: root.selectedIndex
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) {
                                positionViewAtIndex(currentIndex, ListView.Contain);
                            }
                        }

                        delegate: Rectangle {
                            width: appList.width
                            height: root.itemHeight
                            color: index === root.selectedIndex ? Common.Theme.background2 : "transparent"
                            radius: Common.Theme.radius.small

                            property bool isHovered: mouseArea.containsMouse

                            onIsHoveredChanged: {
                                if (isHovered) {
                                    root.selectedIndex = index;
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 8

                                Image {
                                    source: model.iconPath || root.fallbackIcon
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    asynchronous: true
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: model.name
                                        color: Common.Theme.text
                                        font.family: Common.Theme.font.sans.family
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: model.description || ""
                                        visible: text !== ""
                                        color: Common.Theme.text
                                        font.family: Common.Theme.font.sans.family
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = index;
                                    root.launchSelected();
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: appModel.count + " applications"
                        color: Common.Theme.textMuted
                        font.family: Common.Theme.font.sans.family
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignRight
                        visible: appModel.count > 0
                    }
                }
            }
        }

        Common.Border {
            anchors.fill: parent
        }
    }
}
