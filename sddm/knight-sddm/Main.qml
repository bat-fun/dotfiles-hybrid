import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.surfaceColor || "#141312"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property string errorMessage: ""

    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background ? ("file://" + config.background) : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: "#09080c"
        opacity: wallpaper.visible ? 0.62 : 1.0
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.errorMessage = "Authentication failed"
            passwordField.text = ""
            passwordField.focus = true
        }
        function onLoginSucceeded() {
            root.errorMessage = ""
        }
    }

    function attemptLogin() {
        var user = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 1)
        if (!user) {
            user = userBox.currentText
        }
        sddm.login(user, passwordField.text, root.sessionIndex)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24
        width: 340

        // Clock header
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Text {
                id: clockText
                Layout.alignment: Qt.AlignHCenter
                color: config.textColor || "#e5e2e0"
                font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                font.pixelSize: 52
                font.weight: Font.DemiBold
                text: Qt.formatTime(new Date(), "HH:mm")
            }

            Text {
                id: dateText
                Layout.alignment: Qt.AlignHCenter
                color: config.mutedColor || "#919189"
                font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                text: Qt.formatDate(new Date(), "dddd, MMM dd")
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    var now = new Date()
                    clockText.text = Qt.formatTime(now, "HH:mm")
                    dateText.text = Qt.formatDate(now, "dddd, MMM dd")
                }
            }
        }

        // Login card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cardLayout.implicitHeight + 40
            radius: 14
            color: config.cardColor || "#1c1b1a"
            opacity: 0.94
            border.width: 1
            border.color: config.outlineColor || "#464741"

            ColumnLayout {
                id: cardLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                ComboBox {
                    id: userBox
                    Layout.fillWidth: true
                    implicitHeight: 38
                    model: userModel
                    currentIndex: root.userIndex
                    textRole: "name"
                    onCurrentIndexChanged: root.userIndex = currentIndex

                    background: Rectangle {
                        radius: 8
                        color: "#141312"
                        border.width: 1
                        border.color: config.outlineColor || "#464741"
                    }
                    contentItem: Text {
                        leftPadding: 12
                        text: userBox.displayText
                        color: config.textColor || "#e5e2e0"
                        font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    implicitHeight: 40
                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    placeholderTextColor: config.mutedColor || "#919189"
                    color: config.textColor || "#e5e2e0"
                    font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    focus: true
                    leftPadding: 12
                    rightPadding: 12

                    background: Rectangle {
                        radius: 8
                        color: "#141312"
                        border.width: 1
                        border.color: passwordField.activeFocus
                            ? (config.accentColor || "#c7c7bc")
                            : (config.outlineColor || "#464741")
                    }

                    Keys.onReturnPressed: root.attemptLogin()
                    Keys.onEnterPressed: root.attemptLogin()
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.errorMessage.length > 0
                    text: root.errorMessage
                    color: config.errorColor || "#ffb4ab"
                    font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    text: "Unlock"
                    onClicked: root.attemptLogin()

                    background: Rectangle {
                        radius: 8
                        color: parent.hovered ? "#e5e2e0" : (config.accentColor || "#c7c7bc")
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#141312"
                        font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Session & Power footer
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                implicitHeight: 32
                model: sessionModel
                currentIndex: root.sessionIndex
                textRole: "name"
                onCurrentIndexChanged: root.sessionIndex = currentIndex

                background: Rectangle {
                    radius: 8
                    color: config.cardColor || "#1c1b1a"
                    border.width: 1
                    border.color: config.outlineColor || "#464741"
                }
                contentItem: Text {
                    leftPadding: 10
                    text: sessionBox.displayText
                    color: config.mutedColor || "#919189"
                    font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                implicitWidth: 68
                implicitHeight: 32
                text: "Reboot"
                onClicked: sddm.reboot()
                background: Rectangle {
                    radius: 8
                    color: config.cardColor || "#1c1b1a"
                    border.width: 1
                    border.color: config.outlineColor || "#464741"
                }
                contentItem: Text {
                    text: parent.text
                    color: config.mutedColor || "#919189"
                    font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                implicitWidth: 68
                implicitHeight: 32
                text: "Power"
                onClicked: sddm.powerOff()
                background: Rectangle {
                    radius: 8
                    color: config.cardColor || "#1c1b1a"
                    border.width: 1
                    border.color: config.outlineColor || "#464741"
                }
                contentItem: Text {
                    text: parent.text
                    color: config.mutedColor || "#919189"
                    font.family: config.fontFamily || "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
