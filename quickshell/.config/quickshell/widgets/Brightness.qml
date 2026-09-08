import Quickshell
import Quickshell.Io
import QtQuick
import "../theme"
import "../utils"

Item {
    id: root

    property int level: 0
    property bool showTooltip: false
    property bool showBackground: true
    property string device: ""

    implicitWidth: background.width
    implicitHeight: background.height

    function brightnessIcon() {
        const level = root.level;

        if (level <= 0)
            return "󰃞";
        if (level <= 15)
            return "󰃝";
        if (level <= 35)
            return "󰃟";
        if (level <= 55)
            return "󰃠";
        if (level <= 80)
            return "󰃡";
        return "󰃢";
    }

    function setLevel(newLevel) {
        const clamped = Math.max(0, Math.min(100, Math.round(newLevel)));
        const args = ["brightnessctl", "--quiet", "set", `${clamped}%`];
        if (root.device !== "")
            args.splice(1, 0, "--device", root.device);
        Quickshell.execDetached(args);
        root.level = clamped;
    }

    function step(direction) {
        const newLevel = root.level + direction;
        root.setLevel(newLevel);
    }

    function cyclePreset() {
        // Alterna entre 15%, 50% e 100% (ponto intermediário -> alto -> baixo).
        const current = root.level;
        let next;
        if (current < 40)
            next = 50;
        else if (current < 80)
            next = 100;
        else
            next = 15;
        root.setLevel(next);
    }

    function refresh() {
        brightnessQuery.running = true;
    }

    function parseBrightness(output) {
        // Formato machine-readable do brightnessctl:
        // device,class,brightness,percent%,max  (ex.: intel_backlight,backlight,60,15%,400)
        const fields = output.trim().split(",");
        if (fields.length < 4)
            return;

        const percent = parseInt(fields[3], 10);
        if (!isNaN(percent))
            root.level = percent;
    }

    Rectangle {
        id: background

        width: brightnessText.width + 16
        height: brightnessText.height + 16
        color: root.showBackground ? "black" : "transparent"
        opacity: root.showBackground ? 0.7 : 1
        border.width: root.showBackground ? 1 : 0
        radius: root.showBackground ? 9 : 0
    }

    Text {
        id: brightnessText

        anchors.centerIn: background
        color: "#cdd6f4"
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
        text: `${root.brightnessIcon()} ${root.level}%`
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
                root.cyclePreset();
        }
        onWheel: wheel => {
            root.showTooltip = false;
            volumeScroll.handleWheel(wheel.angleDelta.y);
        }
    }

    VolumeScrollHandler {
        id: volumeScroll

        onVolumeStep: direction => root.step(direction)
    }

    PopupWindow {
        id: brightnessToolTip

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
                text: `Brightness ${root.level}%`
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
        id: brightnessQuery

        command: ["bash", "-c", "brightnessctl -m | grep -i backlight | head -n1"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parseBrightness(text)
        }
    }

    // Monitora eventos udev do backlight (teclas de brilho, brightnessctl, etc.)
    // e atualiza o widget imediatamente, sem esperar o timer de polling.
    Process {
        id: brightnessMonitor

        command: ["udevadm", "monitor", "--property", "--subsystem-match=backlight"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const line = data.trim();
                if (line === "ACTION=change")
                    root.refresh();
            }
        }
    }
}
