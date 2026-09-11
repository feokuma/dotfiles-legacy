import QtQuick
import "../theme"

// Botão individual de workspace, inspirado no módulo
// `hyprland/workspaces` do waybar (on-click: activate).
Rectangle {
    id: root

    // Objeto workspace exposto pelo HyprlandIpc (Hyprland.workspaces)
    property var workspace: null

    readonly property bool isActive: workspace?.active ?? false
    readonly property bool isUrgent: workspace?.urgent ?? false

    width: buttonText.width + 15
    // Mesmo critério de altura dos demais pills da barra (Clock, Battery,
    // Brightness...): texto + 16 de padding total no pill. Como o pill de
    // Workspaces soma row.height + 4, o botão usa texto + 12 para que o
    // pill finalize em texto + 16, acompanhando Theme.fontSize.
    height: buttonText.height + 12
    radius: 9
    color: "transparent"

    // Estados visuais (estilo Catppuccin, seguindo o waybar)
    states: [
        State {
            name: "active"
            when: root.isActive
            PropertyChanges {
                target: root
                color: "#cdd6f4" // text
            }
            PropertyChanges {
                target: buttonText
                color: "#1e1e2e" // base
            }
        },
        State {
            name: "urgent"
            when: root.isUrgent && !root.isActive
            PropertyChanges {
                target: root
                color: "#a6e3a1" // green
            }
            PropertyChanges {
                target: buttonText
                color: "#1e1e2e"
            }
        }
    ]

    Text {
        id: buttonText

        anchors.centerIn: parent
        text: root.workspace?.name ?? ""
        color: "#a6adc8" // subtext0
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            if (!root.isActive && !root.isUrgent) {
                root.color = "#1e1e2e"; // base
                buttonText.color = "#cdd6f4";
            }
        }
        onExited: {
            if (!root.isActive && !root.isUrgent) {
                root.color = "transparent";
                buttonText.color = "#a6adc8";
            }
        }
        onClicked: root.workspace?.activate()
    }
}
