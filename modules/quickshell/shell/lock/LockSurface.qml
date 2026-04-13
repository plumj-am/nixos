import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../common" as Common

WlSessionLockSurface {
    id: root

    required property var pam

    // Exposed for Lock.qml to call
    function clearInput() {
        passwordField.text = "";
        passwordField.forceActiveFocus();
    }

    function showError() {
        errorText.visible = true;
        shakeAnim.running = true;
        errorTimer.restart();
    }

    function submitPassword() {
        if (passwordField.text.length > 0 && pam.responseRequired) {
            pam.respond(passwordField.text);
            passwordField.text = "";
        }
    }

    // Blurred screenshot background
    ScreencopyView {
        id: screencopy
        anchors.fill: parent
        captureSource: root.screen
        live: false

        layer.enabled: true
        layer.effect: FastBlur {
            radius: 64
        }

        // Dim overlay
        Rectangle {
            anchors.fill: parent
            color: "#CC000000"
        }
    }

    // Center lock content
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        // Time
        Text {
            Layout.alignment: Qt.AlignHCenter
            font.family: Common.Theme.font.sans.family
            font.pixelSize: 64
            font.weight: Font.Bold
            color: Common.Theme.text
            renderType: Text.QtRendering

            text: {
                const now = new Date();
                return Qt.formatTime(now, "hh:mm:ss");
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm:ss");
            }
        }

        // Date
        Text {
            Layout.alignment: Qt.AlignHCenter
            font.family: Common.Theme.font.sans.family
            font.pixelSize: 24
            color: Common.Theme.textMuted
            renderType: Text.QtRendering

            text: {
                const now = new Date();
                return Qt.formatDate(now, "dddd, d MMMM yyyy");
            }

            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: parent.text = Qt.formatDate(new Date(), "dddd, d MMMM yyyy");
            }
        }

        // Spacer
        Item {
            Layout.preferredHeight: 32
        }

        // Lock icon
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\uf023"
            font.family: Common.Theme.font.icons.family
            font.pixelSize: 28
            color: Common.Theme.textMuted
        }

        // Error text
        Text {
            id: errorText
            Layout.alignment: Qt.AlignHCenter
            text: "Invalid password"
            font.family: Common.Theme.font.sans.family
            font.pixelSize: 14
            color: Common.Theme.error
            visible: false

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: errorText; property: "x"; from: 0; to: -10; duration: 50 }
                NumberAnimation { target: errorText; property: "x"; from: -10; to: 10; duration: 100 }
                NumberAnimation { target: errorText; property: "x"; from: 10; to: -10; duration: 100 }
                NumberAnimation { target: errorText; property: "x"; from: -10; to: 10; duration: 100 }
                NumberAnimation { target: errorText; property: "x"; from: 10; to: 0; duration: 50 }
            }

            Timer {
                id: errorTimer
                interval: 3000
                onTriggered: errorText.visible = false
            }
        }

        // Password input
        TextField {
            id: passwordField
            Layout.preferredWidth: 400
            Layout.alignment: Qt.AlignHCenter
            echoMode: TextInput.Password
            placeholderText: "Password"
            placeholderTextColor: Common.Theme.textMuted
            color: Common.Theme.text
            font.family: Common.Theme.font.sans.family
            font.pixelSize: 15
            horizontalAlignment: TextInput.AlignHCenter

            background: Rectangle {
                color: Common.Theme.background2
                radius: Common.Theme.radius.normal
                border.color: passwordField.activeFocus ? Common.Theme.accent : Common.Theme.outline
                implicitHeight: 44
            }

            Keys.onReturnPressed: root.submitPassword()
            Keys.onEnterPressed: root.submitPassword()
            Keys.onEscapePressed: passwordField.text = ""

            onActiveFocusChanged: {
                if (!activeFocus && !pam.active) {
                    forceActiveFocus();
                }
            }

            Component.onCompleted: forceActiveFocus()
        }

        // Spacer
        Item {
            Layout.preferredHeight: 24
        }

        // Session actions
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Repeater {
                model: [
                    { "icon": "\uf2f1", "name": "Reboot", "action": "reboot" },
                    { "icon": "\uf011", "name": "Shutdown", "action": "shutdown" },
                    { "icon": "\uf236", "name": "Suspend", "action": "suspend" }
                ]

                delegate: Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 60
                    color: sessionMouse.containsMouse ? Qt.alpha(Common.Theme.accent, 0.15) : "transparent"
                    radius: Common.Theme.radius.normal
                    border.color: Common.Theme.outline
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.icon
                            font.family: Common.Theme.font.icons.family
                            font.pixelSize: 18
                            color: sessionMouse.containsMouse ? Common.Theme.accent : Common.Theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.name
                            font.family: Common.Theme.font.sans.family
                            font.pixelSize: 11
                            color: sessionMouse.containsMouse ? Common.Theme.accent : Common.Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.executeSessionAction(modelData.action)
                    }
                }
            }
        }

        // User label
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: pam.user || ""
            font.family: Common.Theme.font.sans.family
            font.pixelSize: 13
            color: Common.Theme.textMuted
        }
    }

    function executeSessionAction(action) {
        const cmd = Common.Utils.sessionCommand(action);
        if (cmd) {
            Quickshell.execDetached({ command: cmd });
        }
    }
}
