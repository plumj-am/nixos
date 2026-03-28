import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../common" as Common
import "../services" as Services

PanelWindow {
    id: root

    property bool isOpen: false
    property string searchText: ""
    property int selectedIndex: 0
    property var filteredApps: []
    property var allApps: []
    property var screen: null

    visible: isOpen
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
    readonly property int maxVisibleItems: 8

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
                apps.push({
                    name: app.name || "Unknown",
                    description: app.genericName || app.comment || "",
                    icon: app.icon || "application-x-executable",
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
        if (!searchText || searchText.trim() === "") {
            filteredApps = allApps.slice(0, 50);
        } else {
            var query = searchText.toLowerCase();
            var results = [];
            for (var i = 0; i < allApps.length; i++) {
                var app = allApps[i];
                var name = (app.name || "").toLowerCase();
                var desc = (app.description || "").toLowerCase();
                if (name.indexOf(query) !== -1 || desc.indexOf(query) !== -1) {
                    results.push(app);
                }
            }
            filteredApps = results.slice(0, 50);
        }
        selectedIndex = 0;
    }

    onSearchTextChanged: filterApps()

    function launchSelected() {
        if (filteredApps.length > 0 && filteredApps[selectedIndex]) {
            var app = filteredApps[selectedIndex].app;
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

    Common.FlaredRect {
        id: launcherBox
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.isOpen ? barHeight : barHeight - 10
        width: launcherWidth
        height: launcherHeight
        flareLeft: true
        flareRight: true
        clip: true
        opacity: root.isOpen ? 1.0 : 0.0
        z: 1

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.topMargin: launcherBox.f + 12
            anchors.bottomMargin: 12
            anchors.leftMargin: launcherBox.f + 8
            anchors.rightMargin: launcherBox.f + 8
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Search applications..."
                text: root.searchText
                onTextChanged: root.searchText = text
                color: Common.Theme.text
                placeholderTextColor: Common.Theme.textMuted
                font.family: Common.Theme.font.sans.family
                font.pixelSize: 14
                background: Rectangle {
                    color: Common.Theme.background
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
                    if (root.selectedIndex < root.filteredApps.length - 1) {
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
                model: root.filteredApps
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

                        IconImage {
                            source: modelData.icon ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            implicitSize: 32
                            asynchronous: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name
                                color: Common.Theme.text
                                font.family: Common.Theme.font.sans.family
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.description || ""
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
                text: root.filteredApps.length + " applications"
                color: Common.Theme.textMuted
                font.family: Common.Theme.font.sans.family
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
                visible: root.filteredApps.length > 0
            }
        }
    }
}
