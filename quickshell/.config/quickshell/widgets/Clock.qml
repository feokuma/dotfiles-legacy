import Quickshell
import QtQuick
import "../theme"

Item {
    id: root

    implicitWidth: background.width
    implicitHeight: background.height

    Rectangle {
        id: background
        color: "black"
        radius: 9
        opacity: 0.7

        height: clockText.height + 16
        width: clockText.width + 16
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText

        anchors.centerIn: background
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: "#fab387"

        text: Qt.formatDateTime(systemClock.date, "  hh:mm AP")
    }
}
