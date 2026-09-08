import Quickshell
import QtQuick
import "../theme"

Item {
    id: root

    implicitWidth: background.width
    implicitHeight: background.height

    Rectangle {
        id: background

        width: powerText.width + 16
        height: powerText.height + 16
        radius: 9
        color: "black"
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

        // TODO: abrir o menu de logoff / reboot / poweroff.
        onClicked: {}
    }
}
