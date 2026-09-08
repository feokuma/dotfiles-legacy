import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../theme"

Item {
    id: root

    visible: SystemTray.items.values.length > 0

    implicitWidth: background.width
    implicitHeight: background.height

    Rectangle {
        id: background

        width: trayRow.width + 12
        height: trayRow.height + 12
        color: "black"
        opacity: 0.7
        border.width: 1
        radius: 9
    }

    Row {
        id: trayRow

        anchors.centerIn: background
        spacing: 2

        Repeater {
            model: SystemTray.items.values

            delegate: TrayItem {
                trayItem: modelData
            }
        }
    }
}