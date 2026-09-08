import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../theme"

// Gerenciador de workspaces inspirado no módulo `hyprland/workspaces` do
// waybar. Lista todos os workspaces, ativa ao clicar (on-click: activate)
// e destaca o workspace ativo/urgente.
Item {
    id: root

    implicitWidth: background.width
    implicitHeight: background.height

    Rectangle {
        id: background

        color: "black"
        radius: 9
        opacity: 0.7

        width: row.width + 12
        height: row.height + 4
    }

    Row {
        id: row

        anchors {
            top: parent.top
            topMargin: 2
            left: parent.left
            leftMargin: 6
        }

        spacing: 2

        Repeater {
            // Modelo com todos os workspaces gerenciados pelo Hyprland
            model: Hyprland.workspaces
            delegate: WorkspaceButton {
                // modelData já é o objeto HyprlandWorkspace
                workspace: modelData
            }
        }
    }
}
