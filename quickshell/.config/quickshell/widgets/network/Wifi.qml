import Quickshell
import Quickshell.Io
import QtQuick
import "../../theme"

Item {
    id: root

    property int signalStrength: 0
    property bool connected: false
    property string networkName: ""
    property string interfaceName: ""
    property string ipAddress: ""
    property bool showTooltip: false
    property bool showBackground: true

    implicitWidth: background.width
    implicitHeight: background.height

    function updateStatus(output) {
        const lines = output.trim().split("\n");
        const activeNetwork = lines.find(line => line.startsWith("*:"));

        if (!activeNetwork) {
            connected = false;
            signalStrength = 0;
            networkName = "";
            interfaceName = "";
            ipAddress = "";
            return;
        }

        const fields = activeNetwork.split(":");
        connected = true;
        signalStrength = Number(fields[1]) || 0;
        interfaceName = fields[2];
        networkName = fields.slice(3).join(":");

        if (!ipQuery.running)
            ipQuery.running = true;
    }

    Rectangle {
        id: background

        width: wifiText.width + 16
        height: wifiText.height + 16
        color: root.showBackground ? "black" : "transparent"
        opacity: root.showBackground ? 0.7 : 1
        border.width: root.showBackground ? 1 : 0
        radius: root.showBackground ? 9 : 0
    }

    Text {
        id: wifiText

        anchors.centerIn: background
        color: "#f9e2af"
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
        text: root.connected ? `  ${root.signalStrength}%` : "󰖪"
    }

    HoverHandler {
        id: hoverHandler

        onHoveredChanged: {
            if (hovered)
                tooltipDelay.restart();
            else {
                tooltipDelay.stop();
                root.showTooltip = false;
            }
        }
    }

    PopupWindow {
        id: wifiToolTip

        anchor {
            item: root
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins.bottom: 4
        }
        visible: root.showTooltip && hoverHandler.hovered
        implicitWidth: tooltipText.implicitWidth + 24
        implicitHeight: tooltipText.implicitHeight + 16
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"
            radius: 10
            border.width: 2
            border.color: "#11111b"

            Text {
                id: tooltipText

                anchors.centerIn: parent
                text: root.connected
                    ? `${root.networkName} (${root.signalStrength}%)\n${root.ipAddress}`
                    : "Disconnected"
                color: "#cdd6f4"
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                font.pixelSize: Theme.fontSize
            }
        }
    }

    Timer {
        id: tooltipDelay

        interval: 300
        onTriggered: root.showTooltip = true
    }

    Process {
        id: wifiQuery

        command: ["nmcli", "-t", "--escape", "no", "-f", "IN-USE,SIGNAL,DEVICE,SSID", "device", "wifi", "list", "--rescan", "no"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.updateStatus(text)
        }
    }

    Process {
        id: ipQuery

        command: ["nmcli", "-g", "IP4.ADDRESS", "device", "show", root.interfaceName]

        stdout: StdioCollector {
            onStreamFinished: root.ipAddress = text.trim().split("\n")[0].split("/")[0]
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!wifiQuery.running)
                wifiQuery.running = true;
        }
    }
}
