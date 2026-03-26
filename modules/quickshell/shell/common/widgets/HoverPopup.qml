import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import ".."

Item {
    id: root

    property Item hoverTarget
    property int anchorPosition: Types.positionTop
    property bool shouldShow: false
    // Generic content to display in the popup
    property Component contentComponent: null

    width: hoverTarget ? hoverTarget.width : 0
    height: hoverTarget ? hoverTarget.height : 0

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: root.onHoveredEntered()
        onExited: root.onHoveredExited()
    }

    Timer {
        id: popupTimer
        interval: 500
        onTriggered: root.open()
    }

    function onHoveredEntered() {
        popupTimer.start()
    }

    function onHoveredExited() {
        popupTimer.stop()
        root.close()
    }

    function open() {
        shouldShow = true
    }

    function close() {
        shouldShow = false
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

            implicitWidth: contentRect.implicitWidth
            implicitHeight: contentRect.implicitHeight + chevron.height * 2

            margins {
                left: {
                    const mapped = root.QsWindow.mapFromItem(
                        root,
                        (root.width - contentRect.implicitWidth)/2, 0
                    )
                    return mapped.x
                }
                top: root.anchorPosition === Types.positionTop ? Config.data.bar.size : 0
                bottom: root.anchorPosition === Types.positionBottom ? Config.data.bar.size : 0
            }

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:hover-popup"
            WlrLayershell.layer: WlrLayer.Top

            Rectangle {
                id: contentRect
                color: Theme.background
                radius: 8
                implicitWidth: contentLoader.implicitWidth + 24
                implicitHeight: contentLoader.implicitHeight + 24
                y: chevron.height

                Loader {
                    id: contentLoader
                    anchors.centerIn: parent
                    sourceComponent: root.contentComponent
                }
            }

            // Chevron element pointing to the hovered component
            Canvas {
                id: chevron
                width: 20
                height: 10
                anchors {
                    horizontalCenter: contentRect.horizontalCenter
                    bottom: root.anchorPosition === Types.positionTop ? contentRect.top : undefined
                    top: root.anchorPosition === Types.positionBottom ? contentRect.bottom : undefined
                }
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = Theme.background
                    ctx.beginPath()
                    if (root.anchorPosition === Types.positionTop) {
                        // Pointing up
                        ctx.moveTo(0, height)
                        ctx.lineTo(width / 2, 0)
                        ctx.lineTo(width, height)
                    } else {
                        // Pointing down
                        ctx.moveTo(0, 0)
                        ctx.lineTo(width / 2, height)
                        ctx.lineTo(width, 0)
                    }
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }
    }
}
