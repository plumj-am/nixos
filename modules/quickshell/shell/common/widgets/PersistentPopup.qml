import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

Item {
    id: root

    property Item hoverTarget
    property int anchorPosition: Types.positionTop
    property int corner: Types.cornerTopLeft
    property bool shouldShow: false
    property Component contentComponent: null
    property int openCloseDelay: 200
    property bool fillRemainingWidth: false
    property int fixedWidth: -1

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

    function getScreen() {
        return root.hoverTarget ? root.hoverTarget.QsWindow.screen : null;
    }

    function getAvailableWidth() {
        const screen = getScreen();
        return screen ? screen.width - (Theme.margin.normal * 2) : 400;
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
                left: root.corner === Types.cornerTopLeft
                right: root.corner === Types.cornerTopRight
                top: root.anchorPosition === Types.positionTop
                bottom: root.anchorPosition === Types.positionBottom
            }

            implicitWidth: root.fixedWidth > 0 ? root.fixedWidth + contentRect.flare : (root.fillRemainingWidth ? root.getAvailableWidth() : contentRect.implicitWidth)
            implicitHeight: contentRect.implicitHeight

            margins {
                left: 0
                right: 0
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

            property bool isLeftEdge: root.corner === Types.cornerTopLeft
            property bool isTopEdge: root.anchorPosition === Types.positionTop

            Item {
                id: container
                anchors.fill: parent

                Canvas {
                    id: contentRect

                    readonly property real r: Theme.radius.big
                    readonly property real flare: Config.data.bar.size

                    property real contentImplicitWidth: contentLoader.implicitWidth + 24 + flare
                    property real contentImplicitHeight: contentLoader.implicitHeight + 24
                    implicitWidth: contentImplicitWidth
                    implicitHeight: contentImplicitHeight
                    width: root.fixedWidth > 0 ? root.fixedWidth + flare : (root.fillRemainingWidth ? parent.width : implicitWidth)
                    height: implicitHeight
                    x: popupWindow.isLeftEdge ? 0 : parent.width - width
                    y: popupWindow.isTopEdge ? 0 : parent.height - height

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.beginPath();

                        var w = width;
                        var h = height;
                        var r = contentRect.r;
                        var f = contentRect.flare;

                        // Helper: draw full shape path (closed)
                        function drawShape() {
                            if (popupWindow.isLeftEdge && popupWindow.isTopEdge) {
                                // Flare at top-right: quarter circle from (w,0) to (w-f,f)
                                ctx.moveTo(0, 0);
                                ctx.lineTo(w, 0);
                                ctx.arc(w, f, f, 3 * Math.PI / 2, Math.PI, true);
                                ctx.lineTo(w - f, h - r);
                                ctx.arcTo(w - f, h, w - f - r, h, r);
                                ctx.lineTo(0, h);
                            } else if (!popupWindow.isLeftEdge && popupWindow.isTopEdge) {
                                // Flare at top-left: quarter circle from (0,0) to (f,f)
                                ctx.moveTo(0, 0);
                                ctx.lineTo(w, 0);
                                ctx.lineTo(w, h);
                                ctx.lineTo(f + r, h);
                                ctx.arcTo(f, h, f, h - r, r);
                                ctx.lineTo(f, f);
                                ctx.arcTo(f, 0, 0, 0, f);
                            } else if (popupWindow.isLeftEdge && !popupWindow.isTopEdge) {
                                // Flare at bottom-right: quarter circle from (w,h) to (w-f,h-f)
                                ctx.moveTo(0, 0);
                                ctx.lineTo(w - f - r, 0);
                                ctx.arcTo(w - f, 0, w - f, r, r);
                                ctx.lineTo(w - f, h - f);
                                ctx.arc(w, h - f, f, Math.PI, Math.PI / 2, true);
                                ctx.lineTo(0, h);
                            } else {
                                // Flare at bottom-left: quarter circle from (0,h) to (f,h-f)
                                ctx.moveTo(0, h);
                                ctx.lineTo(w, h);
                                ctx.lineTo(w, 0);
                                ctx.lineTo(f + r, 0);
                                ctx.arcTo(f, 0, f, r, r);
                                ctx.lineTo(f, h - f);
                                ctx.arcTo(0, h - f, 0, h, f);
                            }
                            ctx.closePath();
                        }

                        // Fill the shape
                        drawShape();
                        ctx.fillStyle = Theme.background;
                        ctx.fill();

                        // Stroke only the non-bar edges (skip top for top bar, bottom for bottom bar)
                        ctx.strokeStyle = Theme.outline;
                        ctx.lineWidth = 1;

                        if (popupWindow.isLeftEdge && popupWindow.isTopEdge) {
                            // Skip top edge; stroke: left + bottom + bottom-right round + right content + flare
                            ctx.beginPath();
                            ctx.moveTo(0, 0);
                            ctx.lineTo(0, h);
                            ctx.lineTo(w - f - r, h);
                            ctx.arcTo(w - f, h, w - f, h - r, r);
                            ctx.lineTo(w - f, f);
                            ctx.arc(w, f, f, Math.PI, 3 * Math.PI / 2, false);
                            ctx.stroke();
                        } else if (!popupWindow.isLeftEdge && popupWindow.isTopEdge) {
                            // Skip top edge; stroke: right + bottom + bottom-left round + left + flare
                            ctx.beginPath();
                            ctx.moveTo(w, 0);
                            ctx.lineTo(w, h);
                            ctx.lineTo(f + r, h);
                            ctx.arcTo(f, h, f, h - r, r);
                            ctx.lineTo(f, f);
                            ctx.arcTo(f, 0, 0, 0, f);
                            ctx.stroke();
                        } else if (popupWindow.isLeftEdge && !popupWindow.isTopEdge) {
                            // Skip bottom edge; stroke: left + top + top-right round + right content + flare
                            ctx.beginPath();
                            ctx.moveTo(0, h);
                            ctx.lineTo(0, 0);
                            ctx.lineTo(w - f - r, 0);
                            ctx.arcTo(w - f, 0, w - f, r, r);
                            ctx.lineTo(w - f, h - f);
                            ctx.arc(w, h - f, f, Math.PI / 2, Math.PI, false);
                            ctx.stroke();
                        } else {
                            // Skip bottom edge; stroke: right + top + top-left round + left + flare
                            ctx.beginPath();
                            ctx.moveTo(w, h);
                            ctx.lineTo(w, 0);
                            ctx.lineTo(f + r, 0);
                            ctx.arcTo(f, 0, f, r, r);
                            ctx.lineTo(f, h - f);
                            ctx.arcTo(0, h - f, 0, h, f);
                            ctx.stroke();
                        }
                    }

                    Loader {
                        id: contentLoader
                        anchors.left: parent.left
                        anchors.right: root.fillRemainingWidth ? parent.right : undefined
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        anchors.leftMargin: 12 + (popupWindow.isLeftEdge ? 0 : contentRect.flare)
                        anchors.rightMargin: root.fillRemainingWidth && popupWindow.isLeftEdge ? (12 + contentRect.flare) : 12
                        width: root.fillRemainingWidth ? undefined : implicitWidth
                        sourceComponent: root.contentComponent
                    }

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Binding {
                    target: root
                    property: "estimatedContentWidth"
                    value: contentRect.implicitWidth
                }
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
        }
    }
}
