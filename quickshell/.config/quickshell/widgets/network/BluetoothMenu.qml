import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland._FocusGrab
import QtQuick
import QtQuick.Layouts
import "../../theme"

PopupWindow {
    id: root

    color: "transparent"

    // Imperative visibility control (no external binding on `visible`),
    // so closing from an outside click does not break the binding.
    function openMenu() {
        root.visible = true;
    }

    function closeMenu() {
        root.visible = false;
    }

    anchor {
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.bottom: 4
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: root.adapter ? root.adapter.enabled : false
    readonly property bool discovering: root.adapter ? root.adapter.discovering : false

    implicitWidth: 340
    implicitHeight: mainColumn.implicitHeight + 24

    // Close the popup when the user clicks outside of it (hyprland_focus_grab_v1 protocol).
    HyprlandFocusGrab {
        id: focusGrab

        windows: [root]
        onCleared: root.closeMenu()
    }

    // The grab only engages once the popup surface is ready; activating right when
    // `visible` flips silently fails, so retry until the grab is actually active.
    function refreshGrab() {
        if (root.visible && !focusGrab.active) {
            focusGrab.active = false;
            focusGrab.active = true;
        }
    }

    Timer {
        id: grabRetry

        interval: 200
        repeat: true
        running: root.visible
        onTriggered: root.refreshGrab()
    }

    // Start scanning when the menu opens and stop when it closes.
    onVisibleChanged: {
        if (root.visible) {
            if (root.powered && root.adapter)
                root.adapter.discovering = true;
            root.refreshGrab();
        } else {
            if (root.adapter)
                root.adapter.discovering = false;
            focusGrab.active = false;
            grabRetry.stop();
        }
    }

    // If the menu is already open and Bluetooth gets turned on, start scanning.
    onPoweredChanged: {
        if (root.visible && root.powered && root.adapter)
            scanRetry.start();
    }

    // BlueZ may reject discovery right after powering on the adapter; try again.
    Timer {
        id: scanRetry

        interval: 700
        repeat: false
        onTriggered: {
            if (root.visible && root.powered && root.adapter && !root.adapter.discovering)
                root.adapter.discovering = true;
        }
    }

    function iconFor(iconName) {
        switch (iconName) {
        case "input-keyboard": return "󰌌";
        case "input-mouse": return "󰍽";
        case "phone": return "󰏲";
        case "audio-headset":
        case "audio-headphones": return "󰋋";
        case "audio-card":
        case "audio-speakers": return "󰓃";
        case "computer":
        case "laptop": return "󰌢";
        case "video-display":
        case "tv": return "󰥶";
        case "watch": return "󰖀";
        default: return "󰂯";
        }
    }

    function deviceStatusText(device) {
        if (device.state === BluetoothDeviceState.Connected) return "Connected";
        if (device.state === BluetoothDeviceState.Connecting) return "Connecting...";
        if (device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting...";
        if (device.pairing) return "Pairing...";
        if (device.paired) return "Paired";
        return "Available";
    }

    function deviceStatusColor(device) {
        if (device.connected) return "#a6e3a1";
        if (device.pairing || device.state === BluetoothDeviceState.Connecting
                || device.state === BluetoothDeviceState.Disconnecting) return "#f9e2af";
        if (device.paired) return "#89b4fa";
        return "#6c7086";
    }

    function activateDevice(device) {
        if (!device) return;
        if (device.connected) {
            device.disconnect();
            return;
        }
        if (device.pairing || device.state === BluetoothDeviceState.Connecting
                || device.state === BluetoothDeviceState.Disconnecting) return;
        if (!device.paired) device.pair();
        device.connect();
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        radius: 10
        border.width: 2
        border.color: "#11111b"
        clip: true

        ColumnLayout {
            id: mainColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 10
            }
            spacing: 6

            // ===== Header: title + toggle =====
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰂯"
                    color: root.powered ? "#89b4fa" : "#6c7086"
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    text: "Bluetooth"
                    color: "#cdd6f4"
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    font.pixelSize: Theme.fontSize
                    Layout.fillWidth: true
                }

                Rectangle {
                    id: toggleTrack

                    implicitWidth: 44
                    implicitHeight: 22
                    radius: 11
                    color: root.powered ? "#a6e3a1" : "#45475a"
                    opacity: root.adapter ? 1 : 0.5

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Rectangle {
                        id: toggleKnob

                        width: 16
                        height: 16
                        radius: 8
                        color: "#1e1e2e"
                        y: (parent.height - height) / 2
                        x: root.powered ? parent.width - width - 3 : 3

                        Behavior on x {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.adapter !== null
                        onClicked: root.adapter.enabled = !root.adapter.enabled
                    }
                }
            }

            // ===== Separator =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#313244"
            }

            // ===== State: disabled =====
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                visible: !root.powered
                text: root.adapter ? "Bluetooth off" : "Bluetooth unavailable"
                color: "#6c7086"
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // ===== Device list =====
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.powered
                spacing: 4

                ListView {
                    id: deviceList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(deviceList.contentHeight, 280)
                    clip: true
                    spacing: 4
                    model: Bluetooth.devices
                    interactive: deviceList.contentHeight > deviceList.height

                    delegate: Rectangle {
                        required property var modelData

                        width: deviceList.width
                        height: 34
                        radius: 7
                        color: rowMouse.hovered ? "#313244" : "transparent"

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 8
                                rightMargin: 8
                            }
                            spacing: 8

                            Text {
                                text: root.iconFor(modelData.icon)
                                color: modelData.connected ? "#a6e3a1" : "#6c7086"
                                font.family: Theme.fontFamily
                                font.bold: Theme.fontBold
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                text: modelData.name || modelData.address
                                color: "#cdd6f4"
                                font.family: Theme.fontFamily
                                font.bold: Theme.fontBold
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.batteryAvailable
                                    ? `󰁹 ${Math.round(modelData.battery * 100)}%` : ""
                                color: "#a6e3a1"
                                visible: text !== ""
                                font.family: Theme.fontFamily
                                font.bold: Theme.fontBold
                                font.pixelSize: Theme.fontSize - 2
                            }

                            Text {
                                text: root.deviceStatusText(modelData)
                                color: root.deviceStatusColor(modelData)
                                font.family: Theme.fontFamily
                                font.bold: Theme.fontBold
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.activateDevice(modelData)
                        }
                    }
                }

                // Empty list
                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    visible: deviceList.count === 0
                    text: root.discovering ? "Scanning for devices..." : "No devices found"
                    color: "#6c7086"
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // Scanning indicator
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.discovering && deviceList.count > 0
                    spacing: 8

                    Text {
                        text: "󰐎"
                        color: "#89b4fa"
                        font.family: Theme.fontFamily
                        font.bold: Theme.fontBold
                        font.pixelSize: Theme.fontSize

                        NumberAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: root.discovering
                        }
                    }

                    Text {
                        text: "Scanning for devices..."
                        color: "#89b4fa"
                        font.family: Theme.fontFamily
                        font.bold: Theme.fontBold
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            // ===== Footer: start/stop scan =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 7
                color: scanHover.hovered ? "#313244" : "transparent"
                enabled: root.powered && root.adapter !== null

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: root.discovering ? "󰂲" : "󰐎"
                        color: "#89b4fa"
                        font.family: Theme.fontFamily
                        font.bold: Theme.fontBold
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        text: root.discovering ? "Stop scan" : "Scan for devices"
                        color: root.powered ? "#89b4fa" : "#6c7086"
                        font.family: Theme.fontFamily
                        font.bold: Theme.fontBold
                        font.pixelSize: Theme.fontSize
                    }
                }

                MouseArea {
                    id: scanHover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.powered && root.adapter !== null
                    onClicked: root.adapter.discovering = !root.adapter.discovering
                }
            }
        }
    }
}