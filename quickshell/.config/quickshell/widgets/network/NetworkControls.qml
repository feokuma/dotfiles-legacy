import QtQuick
import "../../theme"

Item {
    id: root

    implicitWidth: controls.implicitWidth
    implicitHeight: controls.implicitHeight

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.7
        border.width: 1
        radius: 9
    }

    Row {
        id: controls

        spacing: 0

        Wifi {
            showBackground: false
        }

        Bluetooth {
            showBackground: false
        }
    }
}