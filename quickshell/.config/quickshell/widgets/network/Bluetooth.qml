import Quickshell
import Quickshell.Bluetooth
import QtQuick
import "../../theme"

Item {
    id: root

    property bool showTooltip: false
    property bool showBackground: true
    property real iconScale: 1
    property int deviceCount: 0
    property string tooltipText: "Bluetooth off"
    property var watched: ({})

    readonly property bool powered: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false

    implicitWidth: background.width
    implicitHeight: background.height

    function refresh() {
        let count = 0;
        const names = [];
        const vals = Bluetooth.devices.values;

        for (let i = 0; i < vals.length; i++) {
            const d = vals[i];
            if (d.connected) {
                count++;
                names.push(d.name || d.address);
            }
            // Watch each device's connection changes to update reactively.
            if (!root.watched[d.address]) {
                d.connectedChanged.connect(root.refresh);
                root.watched[d.address] = true;
            }
        }

        root.deviceCount = count;
        root.tooltipText = !root.powered
            ? "Bluetooth off"
            : count > 0
                ? `󰂯 ${count} connected${count > 1 ? "s" : ""}\n${names.join("\n")}`
                : "Bluetooth on\nNo devices connected";
    }

    onPoweredChanged: root.refresh()

    Component.onCompleted: {
        Bluetooth.devices.valuesChanged.connect(root.refresh);
        root.refresh();
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
        text: root.powered && root.deviceCount > 0 ? `󰂯 ${root.deviceCount}` : "󰂯"
    }

    MouseArea {
        anchors.fill: background
        hoverEnabled: true

        onClicked: bluetoothMenu.visible = !bluetoothMenu.visible

        onEntered: tooltipDelay.restart()
        onExited: {
            tooltipDelay.stop();
            root.showTooltip = false;
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
        visible: root.showTooltip && !bluetoothMenu.visible
        implicitWidth: tooltipTextItem.implicitWidth + 24
        implicitHeight: tooltipTextItem.implicitHeight + 16
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"
            radius: 10
            border.width: 2
            border.color: "#11111b"

            Text {
                id: tooltipTextItem

                anchors.centerIn: parent
                text: root.tooltipText
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

    BluetoothMenu {
        id: bluetoothMenu

        anchor.item: root
    }
}