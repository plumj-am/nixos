import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

Item {
    id: root

    property Item hoverTarget
    property int anchorPosition: Types.positionTop
    property int anchorHAlign: Types.alignCenter
    property bool shouldShow: false
    property Component contentComponent: null
    property int openCloseDelay: 200
    property bool fillRemainingWidth: false

    property bool targetHovered: false
    property bool popupHovered: false

    width: hoverTarget ? hoverTarget.width : 0
    height: hoverTarget ? hoverTarget.height : 0

    Timer {
        id: openTimer
        interval: root.openCloseDelay
        onTriggered: root.open()
    }

    Timer {
        id: closeTimer
        interval: root.openCloseDelay
        onTriggered: {
            if (!root.targetHovered && !root.popupHovered) {
                root.close();
            }
        }
    }

    function open() {
        closeTimer.stop();
        shouldShow = true;
    }

    function close() {
        shouldShow = false;
    }

    function onHoveredEntered() {
        root.targetHovered = true;
        closeTimer.stop();
        openTimer.start();
    }

    function onHoveredExited() {
        root.targetHovered = false;
        closeTimer.start();
    }

    property int estimatedContentWidth: 400

    function getLeftMargin() {
        if (anchorHAlign === Types.alignLeft) {
            const mapped = root.QsWindow.mapFromItem(root, 0, 0);
            return mapped.x;
        } else if (anchorHAlign === Types.alignRight) {
            const mapped = root.QsWindow.mapFromItem(root, root.width - root.estimatedContentWidth, 0);
            return mapped.x;
        } else {
            const mapped = root.QsWindow.mapFromItem(root, (root.width - root.estimatedContentWidth) / 2, 0);
            return mapped.x;
        }
    }

    function getAvailableWidth() {
        const leftMargin = getLeftMargin();
        const targetScreen = root.hoverTarget ? root.hoverTarget.QsWindow.screen : null;
        return targetScreen ? targetScreen.width - leftMargin - Theme.margin.normal : 400;
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: root.onHoveredEntered()
        onExited: root.onHoveredExited()
    }

    LazyLoader {
        active: root.shouldShow

        component: PanelWindow {
            id: popupWindow
            color: "transparent"

            anchors {
                left: true
                right: true
                top: root.anchorPosition === Types.positionTop
                bottom: root.anchorPosition === Types.positionBottom
            }

            implicitWidth: root.fillRemainingWidth ? root.getAvailableWidth() : contentRect.implicitWidth
            implicitHeight: contentRect.implicitHeight

            margins {
                left: root.getLeftMargin()
                top: root.anchorPosition === Types.positionTop ? Config.data.bar.size : 0
                bottom: root.anchorPosition === Types.positionBottom ? Config.data.bar.size : 0
            }

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:persistent-popup"
            WlrLayershell.layer: WlrLayer.Top

            onVisibleChanged: {
                if (!visible) {
                    root.shouldShow = false;
                }
            }

            Rectangle {
                id: contentRect
                color: Theme.background
                radius: Theme.radius.big
                border.width: 1
                border.color: Theme.alpha(Theme.outline, 0.3)
                implicitWidth: contentLoader.implicitWidth + 24
                implicitHeight: contentLoader.implicitHeight + 24
                width: root.fillRemainingWidth ? parent.width : implicitWidth
                height: implicitHeight

                Binding {
                    target: root
                    property: "estimatedContentWidth"
                    value: contentRect.implicitWidth
                }

                HoverHandler {
                    id: popupHoverHandler
                    onHoveredChanged: {
                        root.popupHovered = hovered;
                        if (hovered) {
                            closeTimer.stop();
                        } else {
                            closeTimer.start();
                        }
                    }
                }

                Loader {
                    id: contentLoader
                    anchors.left: parent.left
                    anchors.right: root.fillRemainingWidth ? parent.right : undefined
                    anchors.top: parent.top
                    anchors.margins: 12
                    width: root.fillRemainingWidth ? undefined : implicitWidth
                    sourceComponent: root.contentComponent
                }
            }
        }
    }
}
