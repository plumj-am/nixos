import QtQuick

Item {
    id: root

    property color iconColor: "white"
    property bool isHorizontal: true
    property real size: 20

    readonly property real borderWidth: size * 0.05
    readonly property real bodyWidth: body.width
    readonly property real bodyHeight: body.height
    readonly property real bodyRadius: body.radius

    width: isHorizontal ? size : size * 0.6
    height: isHorizontal ? size * 0.6 : size

    Rectangle {
        id: body
        color: "transparent"
        border.color: root.iconColor
        border.width: root.borderWidth
        radius: root.size * 0.1
        width: root.isHorizontal ? root.width * 0.9 : root.width
        height: root.isHorizontal ? root.height : root.height * 0.9
        anchors.left: parent.left
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
        anchors.top: root.isHorizontal ? undefined : nub.bottom
        anchors.bottom: root.isHorizontal ? undefined : parent.bottom
    }

    Rectangle {
        id: nub
        color: root.iconColor
        radius: 0
        width: root.isHorizontal ? root.size * 0.1 : root.size * 0.2
        height: root.isHorizontal ? root.size * 0.2 : root.size * 0.1
        anchors.right: root.isHorizontal ? parent.right : undefined
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
        anchors.top: root.isHorizontal ? undefined : parent.top
        anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
    }
}
