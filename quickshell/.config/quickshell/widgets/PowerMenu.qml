import Quickshell
import Quickshell.Wayland
import QtQuick
import "../theme"

Item {
    id: root

    property bool menuOpen: false

    implicitWidth: background.width
    implicitHeight: background.height

    // Botão da barra que abre a tela de energia.
    Rectangle {
        id: background

        width: powerText.width + 16
        height: powerText.height + 16
        radius: 9
        color: menuOpen ? "#313244" : "black"
        opacity: 0.7
    }

    Text {
        id: powerText

        anchors.centerIn: background
        color: "#cba6f7"
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
        text: "\uf359" // nf-linux-hyprland
    }

    MouseArea {
        anchors.fill: background
        hoverEnabled: true
        onClicked: root.menuOpen = !root.menuOpen
    }

    // Tela de energia em tela cheia, uma por monitor.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay

            property var modelData
            screen: modelData

            visible: root.menuOpen
            color: "transparent"

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            BackgroundEffect.blurRegion: Region {
                x: 0
                y: 0
                width: overlay.width
                height: overlay.height
            }

            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }

            Rectangle {
                anchors.fill: parent
                color: "#cc11111b"
                focus: true

                // Fecha com ESC.
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape)
                        root.menuOpen = false;
                }

                // Clicar fora dos botões fecha a tela.
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.menuOpen = false

                    Row {
                        anchors.centerIn: parent
                        spacing: 24

                        PowerOverlayButton {
                            icon: "\uf08b" // nf-fa-sign_out_alt
                            label: "Log out"
                            accent: "#cba6f7" // mauve
                            onClicked: {
                                root.menuOpen = false;
                                Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                            }
                        }

                        PowerOverlayButton {
                            icon: "\uf021" // nf-fa-refresh
                            label: "Reboot"
                            accent: "#b4befe" // lavender
                            onClicked: {
                                root.menuOpen = false;
                                Quickshell.execDetached(["systemctl", "reboot"]);
                            }
                        }

                        PowerOverlayButton {
                            icon: "\uf011" // nf-fa-power_off
                            label: "Shut down"
                            accent: "#cba6f7" // mauve
                            onClicked: {
                                root.menuOpen = false;
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }
                    }
                }
            }
        }
    }

    // Botão da tela de energia em tela cheia.
    component PowerOverlayButton: Item {
        id: buttonRoot

        required property string icon
        required property string label
        property color accent: "#cdd6f4"
        signal clicked

        width: 180
        height: 170

        Rectangle {
            id: buttonBody

            anchors.fill: parent
            radius: 14
            color: buttonMouse.hovered ? "#313244" : "#1e1e2e"
            border.width: 2
            border.color: buttonMouse.hovered ? buttonRoot.accent : "#11111b"

            Text {
                id: buttonIcon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 28
                color: buttonRoot.accent
                font.family: Theme.fontFamily
                font.pixelSize: 44
                text: buttonRoot.icon
            }

            Text {
                id: buttonLabel

                anchors {
                    bottom: parent.bottom
                    bottomMargin: 24
                    horizontalCenter: parent.horizontalCenter
                }
                text: buttonRoot.label
                color: "#cdd6f4"
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                font.pixelSize: Theme.fontSize
            }
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: buttonRoot.clicked()
        }
    }
}
