import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "../../theme"
import "../../utils"

Item {
    id: root

    property var source: Pipewire.defaultAudioSource
    property var audio: source ? source.audio : null
    property bool showTooltip: false
    property bool showBackground: true
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0

    implicitWidth: background.width
    implicitHeight: background.height

    function changeVolume(direction) {
        if (!audio)
            return;

        Quickshell.execDetached([
            "wpctl",
            "set-volume",
            "--limit",
            "1.0",
            "@DEFAULT_AUDIO_SOURCE@",
            direction > 0 ? "1%+" : "1%-"
        ]);
    }

    Rectangle {
        id: background

        width: microphoneText.width + 16
        height: microphoneText.height + 16
        color: root.showBackground ? "black" : "transparent"
        opacity: root.showBackground ? 0.7 : 1
        border.width: root.showBackground ? 1 : 0
        radius: root.showBackground ? 9 : 0
    }

    Text {
        id: microphoneText

        anchors.centerIn: background
        color: "#cba6f7"
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
        text: !root.audio ? " N/A" : root.audio.muted ? " Muted" : ` ${root.volume}%`
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
            if (mouse.button === Qt.LeftButton && root.audio)
                root.audio.muted = !root.audio.muted;
            else if (mouse.button === Qt.RightButton && !pavucontrol.running)
                pavucontrol.running = true;
        }
        onWheel: wheel => volumeScroll.handleWheel(wheel.angleDelta.y)
    }

    VolumeScrollHandler {
        id: volumeScroll

        onVolumeStep: direction => root.changeVolume(direction)
    }

    PwObjectTracker {
        objects: [root.source]
    }

    PopupWindow {
        anchor {
            item: root
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins.bottom: 4
        }
        visible: root.showTooltip && root.source !== null
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
                text: root.source ? root.source.description : "Microfone indisponível"
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
        id: pavucontrol

        command: ["pavucontrol", "--tab=4"]
    }
}
