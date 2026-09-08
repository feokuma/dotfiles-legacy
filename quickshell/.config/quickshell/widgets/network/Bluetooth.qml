import Quickshell
import Quickshell.Io
import QtQuick
import "../../theme"

Item {
    id: root

    property bool powered: false
    property int deviceCount: 0
    property string deviceList: ""
    property real iconScale: 1
    property bool showTooltip: false
    property bool showBackground: true

    implicitWidth: background.width
    implicitHeight: background.height

    function updateStatus(output) {
        const parts = output.trim().split("|");
        root.powered = parts[0] === "yes";
        root.deviceCount = Number(parts[1]) || 0;
        root.deviceList = parts.slice(2).filter(name => name !== "").join("\n");
    }

    function setPower(on) {
        Quickshell.execDetached(["bluetoothctl", "power", on ? "on" : "off"]);
    }

    function togglePower() {
        setPower(!root.powered);
    }

    Rectangle {
        id: background

        width: bluetoothText.width + 16
        height: bluetoothText.height + 16
        color: root.showBackground ? "black" : "transparent"
        opacity: root.showBackground ? 0.7 : 1
        border.width: root.showBackground ? 1 : 0
        radius: root.showBackground ? 9 : 0
    }

    Text {
        id: bluetoothText

        anchors.centerIn: background
        color: !root.powered ? "#6c7086" : root.deviceCount > 0 ? "#a6e3a1" : "#89b4fa"
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Math.round(Theme.fontSize * root.iconScale)
        text: root.powered && root.deviceCount > 0 ? ` ${root.deviceCount}` : ""
    }

    MouseArea {
        anchors.fill: background
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        onEntered: tooltipDelay.restart()
        onExited: {
            tooltipDelay.stop();
            root.showTooltip = false;
        }
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.togglePower();
            else if (mouse.button === Qt.RightButton && !bluetoothManager.running)
                bluetoothManager.running = true;
        }
    }

    PopupWindow {
        id: bluetoothToolTip

        anchor {
            item: root
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins.bottom: 4
        }
        visible: root.showTooltip
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
                text: !root.powered ? "Bluetooth desligado" : root.deviceCount > 0 ? ` ${root.deviceCount} conectado${root.deviceCount > 1 ? "s" : ""}\n${root.deviceList}` : "Bluetooth ligado\nNenhum dispositivo conectado"
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
        id: bluetoothQuery

        command: ["bash", "-c", "power=$(bluetoothctl show 2>/dev/null | grep -oP 'Powered: \\K\\w+'); count=0; names=''; if [ \"$power\" = \"yes\" ]; then for dev in $(bluetoothctl devices 2>/dev/null | awk '{print $2}'); do info=$(bluetoothctl info \"$dev\" 2>/dev/null); if echo \"$info\" | grep -q 'Connected: yes'; then count=$((count+1)); nm=$(echo \"$info\" | grep -E '^[[:space:]]*Alias:' | sed -E 's/^[[:space:]]*Alias: //'); names=\"$names|$nm\"; fi; done; fi; echo \"$power|$count$names\""]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.updateStatus(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!bluetoothQuery.running)
                bluetoothQuery.running = true;
        }
    }

    Process {
        id: bluetoothManager

        command: ["bluetoothctl"]
    }
}
