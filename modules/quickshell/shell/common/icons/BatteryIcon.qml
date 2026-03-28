import QtQuick

Item {
    id: root

    property color iconColor: "white"
    property real size: 20

    readonly property real borderWidth: size * 0.05

    width: size
    height: size * 0.6

    Rectangle {
        id: body
        color: "transparent"
        border.color: root.iconColor
        border.width: root.borderWidth
        radius: root.size * 0.1
        width: root.width * 0.9
        height: root.height
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: nub
        color: root.iconColor
        radius: 0
        width: root.size * 0.1
        height: root.size * 0.2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
