import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    property var trayItem: null
    property bool showTooltip: false
    readonly property string iconSource: {
        const icon = root.trayItem ? String(root.trayItem.icon || "") : "";
        if (icon === "")
            return "";
        if (icon.startsWith("image://") || icon.startsWith("file:") || icon.startsWith("/") || icon.indexOf("://") !== -1)
            return icon;
        return Quickshell.iconPath(icon, true);
    }
    readonly property bool isSymbolic: {
        const icon = root.trayItem ? String(root.trayItem.icon || "") : "";
        return icon.toLowerCase().includes("symbolic");
    }

    width: 24
    height: 24

    Item {
        id: iconArea

        anchors.centerIn: parent
        width: 18
        height: 18
        opacity: root.trayItem && root.trayItem.status === Status.Passive ? 0.7 : 1.0

        Image {
            id: iconImage

            anchors.fill: parent
            source: root.iconSource
            sourceSize: Qt.size(parent.width, parent.height)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            mipmap: true
        }

        MultiEffect {
            anchors.fill: parent
            source: iconImage
            brightness: root.isSymbolic ? 1.0 : 0.0
            saturation: root.isSymbolic ? 0.0 : 1.0
            colorization: root.isSymbolic ? 1.0 : 0.0
            colorizationColor: "#cdd6f4"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: tooltipDelay.restart()
        onExited: {
            tooltipDelay.stop();
            root.showTooltip = false;
        }
        onClicked: mouse => {
            const item = root.trayItem;
            if (!item)
                return;

            if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton) {
                // Abre o menu quando existe: alguns apps (ex.: Spotify) não
                // implementam Activate, então o menu é a única via confiável.
                if (item.hasMenu)
                    trayMenu.menuOpen = !trayMenu.menuOpen;
                else if (mouse.button === Qt.LeftButton)
                    item.activate();
            } else if (mouse.button === Qt.MiddleButton) {
                item.secondaryActivate();
            }
        }
        onWheel: wheel => {
            if (root.trayItem)
                root.trayItem.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false);
        }
    }

    TrayMenu {
        id: trayMenu

        menuHandle: root.trayItem ? root.trayItem.menu : null
        anchor {
            item: root
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins.bottom: 4
        }
    }

    PopupWindow {
        id: trayTooltip

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
                text: {
                    const item = root.trayItem;
                    if (!item)
                        return "";
                    const title = item.tooltipTitle || item.title || item.id;
                    const description = item.tooltipDescription || "";
                    return description ? `${title}\n${description}` : title;
                }
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
}