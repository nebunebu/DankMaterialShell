import QtQuick
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets

DankModal {
    id: root

    property string passwordInput: ""

    function show() {
        passwordInput = ""
        open()
        Qt.callLater(() => {
            if (contentLoader.item && contentLoader.item.passwordField) {
                contentLoader.item.passwordField.forceActiveFocus()
            }
        })
    }

    shouldBeVisible: false
    width: 420
    height: contentLoader.item ? contentLoader.item.implicitHeight + Theme.spacingM * 2 : 240

    onShouldBeVisibleChanged: () => {
        if (!shouldBeVisible) {
            passwordInput = ""
        }
    }

    onOpened: {
        Qt.callLater(() => {
            if (contentLoader.item && contentLoader.item.passwordField) {
                contentLoader.item.passwordField.forceActiveFocus()
            }
        })
    }

    onBackgroundClicked: () => {
        PolkitService.cancel()
        close()
        passwordInput = ""
    }

    Connections {
        target: PolkitService

        function onAuthenticationRequested() {
            show()
        }

        function onAuthenticationCompleted() {
            close()
            passwordInput = ""
        }

        function onIsResponseRequiredChanged() {
            if (PolkitService.isResponseRequired && root.shouldBeVisible) {
                passwordInput = ""
                if (contentLoader.item && contentLoader.item.passwordField) {
                    contentLoader.item.passwordField.forceActiveFocus()
                }
            }
        }
    }

    content: Component {
        FocusScope {
            id: authContent

            property alias passwordField: passwordField

            anchors.fill: parent
            focus: true
            implicitHeight: mainColumn.implicitHeight

            Keys.onEscapePressed: event => {
                PolkitService.cancel()
                close()
                passwordInput = ""
                event.accepted = true
            }

            Column {
                id: mainColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                anchors.topMargin: Theme.spacingM
                spacing: Theme.spacingM

                Row {
                    width: parent.width

                    Column {
                        width: parent.width - 40
                        spacing: Theme.spacingXS

                        StyledText {
                            text: I18n.tr("Authentication Required")
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            StyledText {
                                text: PolkitService.message
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceTextMedium
                                width: parent.width
                                wrapMode: Text.Wrap
                            }

                            StyledText {
                                visible: PolkitService.supplementaryMessage !== ""
                                text: PolkitService.supplementaryMessage
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                                width: parent.width
                                wrapMode: Text.Wrap
                                opacity: 0.8
                            }

                            StyledText {
                                visible: PolkitService.failed
                                text: I18n.tr("Authentication failed, please try again")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.error
                                width: parent.width
                            }
                        }
                    }

                    DankActionButton {
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        onClicked: () => {
                            PolkitService.cancel()
                            close()
                            passwordInput = ""
                        }
                    }
                }

                StyledText {
                    text: PolkitService.inputPrompt
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    width: parent.width
                    visible: PolkitService.inputPrompt !== ""
                }

                Rectangle {
                    width: parent.width
                    height: 50
                    radius: Theme.cornerRadius
                    color: Theme.surfaceHover
                    border.color: passwordField.activeFocus ? Theme.primary : Theme.outlineStrong
                    border.width: passwordField.activeFocus ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        onClicked: () => {
                            passwordField.forceActiveFocus()
                        }
                    }

                    DankTextField {
                        id: passwordField

                        anchors.fill: parent
                        font.pixelSize: Theme.fontSizeMedium
                        textColor: Theme.surfaceText
                        text: passwordInput
                        echoMode: PolkitService.responseVisible ? TextInput.Normal : TextInput.Password
                        placeholderText: I18n.tr("Password")
                        backgroundColor: "transparent"
                        enabled: root.shouldBeVisible
                        onTextEdited: () => {
                            passwordInput = text
                        }
                        onAccepted: () => {
                            if (passwordInput.length > 0) {
                                PolkitService.submit(passwordInput)
                                passwordInput = ""
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 40

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        Rectangle {
                            width: Math.max(70, cancelText.contentWidth + Theme.spacingM * 2)
                            height: 36
                            radius: Theme.cornerRadius
                            color: cancelArea.containsMouse ? Theme.surfaceTextHover : "transparent"
                            border.color: Theme.surfaceVariantAlpha
                            border.width: 1

                            StyledText {
                                id: cancelText

                                anchors.centerIn: parent
                                text: I18n.tr("Cancel")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: cancelArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: () => {
                                    PolkitService.cancel()
                                    close()
                                    passwordInput = ""
                                }
                            }
                        }

                        Rectangle {
                            width: Math.max(80, authText.contentWidth + Theme.spacingM * 2)
                            height: 36
                            radius: Theme.cornerRadius
                            color: authArea.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary
                            enabled: passwordInput.length > 0 || !PolkitService.isResponseRequired
                            opacity: enabled ? 1 : 0.5

                            StyledText {
                                id: authText

                                anchors.centerIn: parent
                                text: I18n.tr("Authenticate")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.background
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: authArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: parent.enabled
                                onClicked: () => {
                                    PolkitService.submit(passwordInput)
                                    passwordInput = ""
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
