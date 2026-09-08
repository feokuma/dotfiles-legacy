import Quickshell
import Quickshell.Io
import QtQuick
import "../theme"

Item {
    id: root

    property int level: 0
    property bool charging: false
    property string stateText: "Carregada"
    property bool showTooltip: false

    implicitWidth: background.width
    implicitHeight: background.height

    function parseBattery(output) {
        const lines = output.trim().split("\n");
        let state = "";
        let sum = 0;
        let count = 0;

        for (const line of lines) {
            const match = line.match(/^\s*(state|percentage):\s*(.+?)\s*$/);
            if (!match)
                continue;

            if (match[1] === "state") {
                const value = match[2].toLowerCase();
                if (value === "charging" || value === "pending-charge")
                    state = "charging";
                else if (state !== "charging" && (value === "discharging" || value === "fully-charged"))
                    state = value;
            } else {
                const percent = parseFloat(match[2]);
                if (!isNaN(percent)) {
                    sum += percent;
                    count++;
                }
            }
        }

        root.level = count ? Math.round(sum / count) : 0;
        root.charging = state === "charging";
        root.stateText = state === "charging" ? "Carregando" : state === "discharging" ? "Descarregando" : "Carregada";
    }

    function batteryIcon() {
        const level = root.level;

        if (root.charging) {
            switch (true) {
            case level >= 95:
                return "󰂆";
            case level >= 85:
                return "󰂏";
            case level >= 75:
                return "󰂎";
            case level >= 65:
                return "󰂍";
            case level >= 55:
                return "󰂌";
            case level >= 45:
                return "󰂋";
            case level >= 35:
                return "󰂊";
            case level >= 25:
                return "󰂉";
            case level >= 15:
                return "󰂈";
            case level >= 5:
                return "󰂇";
            default:
                return "󰂄";
            }
        }

        switch (true) {
        case level >= 95:
            return "󰁹";
        case level >= 85:
            return "󰂂";
        case level >= 75:
            return "󰂁";
        case level >= 65:
            return "󰂀";
        case level >= 55:
            return "󰁿";
        case level >= 45:
            return "󰁾";
        case level >= 35:
            return "󰁽";
        case level >= 25:
            return "󰁼";
        case level >= 15:
            return "󰁻";
        case level >= 5:
            return "󰁺";
        default:
            return "󰂃";
        }
    }

    Rectangle {
        id: background

        width: batteryText.width + 16
        height: batteryText.height + 16
        radius: 9
        color: "black"
        opacity: 0.7
    }

    Text {
        id: batteryText

        anchors.centerIn: background
        color: root.level <= 20 ? "#f38ba8" : "#a6e3a1"
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
        text: `${root.batteryIcon()} ${root.level}%`
    }

    MouseArea {
        anchors.fill: background
        hoverEnabled: true

        onEntered: tooltipDelay.restart()
        onExited: {
            tooltipDelay.stop();
            root.showTooltip = false;
        }
    }

    PopupWindow {
        id: batteryToolTip

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
                text: `${root.stateText} ${root.level}%`
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
        id: batteryQuery

        command: ["bash", "-c", "for b in $(upower -e | grep -iE 'battery'); do upower -i \"$b\"; done | grep -E 'state:|percentage:'"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parseBattery(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!batteryQuery.running)
                batteryQuery.running = true;
        }
    }
}
