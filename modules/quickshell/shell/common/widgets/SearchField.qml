import QtQuick
import QtQuick.Controls
import ".."

TextField {
    id: root

    property string searchQuery: ""
    signal searchTriggered(string query)

    property Timer _debounce: Timer {
        interval: 50
        onTriggered: root.searchTriggered(root.searchQuery)
    }

    onTextChanged: {
        root.searchQuery = text
        root._debounce.restart()
    }

    color: Theme.text
    placeholderTextColor: Theme.textMuted
    font.family: Theme.font.sans.family
    font.pixelSize: 14
    background: Rectangle {
        color: Theme.background2
        radius: Theme.radius.small
        border.color: root.activeFocus ? Theme.background : Theme.outline
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true;
            var cursorPos = root.cursorPosition;
            var text = root.text;
            if (cursorPos === 0)
                return;
            var start = cursorPos - 1;
            while (start > 0 && text.charAt(start - 1) !== ' ') {
                start--;
            }
            root.text = text.substring(0, start) + text.substring(cursorPos);
            root.cursorPosition = start;
        }
    }
}
