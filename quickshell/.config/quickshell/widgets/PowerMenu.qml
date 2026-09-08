import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../theme"

Item {
    id: root

    property bool menuOpen: false

    implicitWidth: background.width
    implicitHeight: background.height

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

    PopupWindow {
        id: popup

        visible: root.menuOpen
        color: "transparent"
        implicitWidth: 180
        implicitHeight: 118

        anchor {
            item: root
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins.bottom: 4
        }

        HyprlandFocusGrab {
            windows: [popup]
            active: root.menuOpen
            onCleared: root.menuOpen = false
        }

        Rectangle {
            id: popupBackground

            anchors.fill: parent
            color: "#1e1e2e"
            radius: 10
            border.width: 2
            border.color: "#11111b"

            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 6
                }
                spacing: 2

                PowerButton {
                    icon: "\uf08b" // nf-fa-sign_out_alt
                    label: "Log out"
                    color: "#f38ba8"
                    onActivated: {
                        root.menuOpen = false;
                        Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                    }
                }

                PowerButton {
                    icon: "\uf021" // nf-fa-refresh
                    label: "Reboot"
                    color: "#f9e2af"
                    onActivated: {
                        root.menuOpen = false;
                        Quickshell.execDetached(["systemctl", "reboot"]);
                    }
                }

                PowerButton {
                    icon: "\uf011" // nf-fa-power_off
                    label: "Shut down"
                    color: "#f38ba8"
                    onActivated: {
                        root.menuOpen = false;
                        Quickshell.execDetached(["systemctl", "poweroff"]);
                    }
                }
            }
        }
    }

    // Item auxiliar: cada linha do menu de energia.
    component PowerButton: Item {
        id: buttonRoot

        required property string icon
        required property string label
        property color color: "#cdd6f4"
        signal activated

        width: parent.width
        height: 34

        Rectangle {
            id: buttonBody

            anchors.fill: parent
            radius: 6
            color: buttonMouse.hovered ? "#313244" : "transparent"
        }

        Row {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 10

            Text {
                id: buttonIcon

                width: 18
                color: buttonRoot.color
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                text: buttonRoot.icon
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                id: buttonLabel

                width: buttonBody.width - 48 // 20 (margins) + 18 (icon) + 10 (spacing)
                text: buttonRoot.label
                color: "#cdd6f4"
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                font.pixelSize: Theme.fontSize - 1
            }
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: buttonRoot.activated()
        }
    }
}
