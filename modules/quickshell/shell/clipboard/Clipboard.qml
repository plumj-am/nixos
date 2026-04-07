import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../common" as Common

PanelWindow {
    id: root

    property bool isOpen: false
    property string searchText: ""
    property int selectedIndex: 0
    property var allEntries: []
    property var filteredEntries: []
    property var screen: null

    visible: isOpen || clipboardClip.implicitHeight > 0
    color: "transparent"

    anchors {
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    readonly property int clipboardWidth: 500
    readonly property int clipboardHeight: 440
    readonly property int itemHeight: 40
    readonly property int maxVisibleItems: 8

    onIsOpenChanged: {
        if (isOpen) {
            searchText = "";
            selectedIndex = 0;
            loadEntries();
            searchField.forceActiveFocus();
        }
    }

    function loadEntries() {
        listProc.running = false;
        listProc.running = true;
    }

    function parseEntries(raw) {
        var lines = raw.split("\n");
        var entries = [];
        for (var i = 0; i < lines.length && entries.length < 50; i++) {
            var line = lines[i].trim();
            if (line === "") continue;
            var parts = line.split("\t");
            if (parts.length < 2) continue;
            var id = parts[0];
            var text = parts.slice(1).join("\t");
            if (text.indexOf("binary data") === 0) continue;
            entries.push({ id: id, text: text });
        }
        allEntries = entries;
        filterEntries();
    }

    function filterEntries() {
        if (!searchText || searchText.trim() === "") {
            filteredEntries = allEntries.slice();
        } else {
            var query = searchText.toLowerCase();
            var results = [];
            for (var i = 0; i < allEntries.length; i++) {
                if (allEntries[i].text.toLowerCase().indexOf(query) !== -1) {
                    results.push(allEntries[i]);
                }
            }
            filteredEntries = results;
        }
        selectedIndex = 0;
    }

    onSearchTextChanged: filterEntries()

    function selectEntry() {
        if (filteredEntries.length > 0 && filteredEntries[selectedIndex]) {
            var id = filteredEntries[selectedIndex].id;
            copyProc.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy"];
            copyProc.running = true;
            isOpen = false;
        }
    }

    function deleteEntry(index) {
        if (filteredEntries[index]) {
            var id = filteredEntries[index].id;
            deleteProc.command = ["cliphist", "delete", id];
            deleteProc.running = true;
            var newAll = [];
            for (var i = 0; i < allEntries.length; i++) {
                if (allEntries[i].id !== id) newAll.push(allEntries[i]);
            }
            allEntries = newAll;
            filterEntries();
        }
    }

    function clearAll() {
        wipeProc.running = true;
        allEntries = [];
        filteredEntries = [];
        isOpen = false;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseEntries(this.text)
        }
    }

    Process {
        id: copyProc
        running: false
    }

    Process {
        id: deleteProc
        running: false
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.isOpen = false
    }

    Item {
        id: clipboardClip
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: clipboardWidth
        implicitHeight: root.isOpen ? clipboardHeight : 0
        visible: implicitHeight > 0

        Behavior on implicitHeight {
            Common.NAnim {}
        }

        clip: true

        Item {
            id: clipboardBody
            anchors.bottom: parent.bottom
            width: clipboardWidth
            height: clipboardHeight

            Rectangle {
                anchors.fill: parent
                color: Common.Theme.background
                radius: 0
                topLeftRadius: Common.Theme.radius.big
                topRightRadius: Common.Theme.radius.big
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
                        placeholderText: "Search clipboard..."
                        text: root.searchText
                        onTextChanged: root.searchText = text
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
                        Keys.onReturnPressed: root.selectEntry()
                        Keys.onEnterPressed: root.selectEntry()
                        Keys.onUpPressed: {
                            if (root.selectedIndex > 0) root.selectedIndex--;
                        }
                        Keys.onDownPressed: {
                            if (root.selectedIndex < root.filteredEntries.length - 1) root.selectedIndex++;
                        }
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier)) {
                                event.accepted = true;
                                var cursorPos = searchField.cursorPosition;
                                var text = searchField.text;
                                if (cursorPos === 0) return;
                                var start = cursorPos - 1;
                                while (start > 0 && text.charAt(start - 1) !== ' ') start--;
                                searchField.text = text.substring(0, start) + text.substring(cursorPos);
                                searchField.cursorPosition = start;
                            }
                        }
                    }

                    ListView {
                        id: entryList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: root.filteredEntries
                        clip: true
                        currentIndex: root.selectedIndex
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain);
                        }

                        delegate: Rectangle {
                            width: entryList.width
                            height: root.itemHeight
                            color: index === root.selectedIndex ? Common.Theme.background2 : "transparent"
                            radius: Common.Theme.radius.small

                            property bool isHovered: delegateMouseArea.containsMouse

                            onIsHoveredChanged: {
                                if (isHovered) root.selectedIndex = index;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 8

                                Text {
                                    text: "\uf0c7"
                                    font.family: Common.Theme.font.mono.family
                                    font.pixelSize: 13
                                    color: Common.Theme.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.text
                                    color: Common.Theme.text
                                    font.family: Common.Theme.font.mono.family
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "\uf00d"
                                    font.family: Common.Theme.font.mono.family
                                    font.pixelSize: 12
                                    color: deleteBtnMA.containsMouse ? Common.Theme.error : Common.Theme.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: delegateMouseArea.containsMouse

                                    MouseArea {
                                        id: deleteBtnMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: function (mouse) {
                                            mouse.accepted = true;
                                            root.deleteEntry(index);
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: delegateMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = index;
                                    root.selectEntry();
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.filteredEntries.length + " entries"
                            color: Common.Theme.textMuted
                            font.family: Common.Theme.font.sans.family
                            font.pixelSize: 11
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Clear all"
                            color: clearAllMA.containsMouse ? Common.Theme.error : Common.Theme.textMuted
                            font.family: Common.Theme.font.sans.family
                            font.pixelSize: 11

                            MouseArea {
                                id: clearAllMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clearAll()
                            }
                        }
                    }
                }
            }
        }
    }
}
