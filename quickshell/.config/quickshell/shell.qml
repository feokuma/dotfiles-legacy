//@ pragma IconTheme Adwaita
import Quickshell
import QtQuick
import QtQuick.Layouts
import "widgets"
import "widgets/network"
import "widgets/audio"

ShellRoot {
    id: root

    PanelWindow {
        id: bar

        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 42

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    spacing: 8

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }

                    PowerMenu {}

                    Workspaces {}
                }
            }

            Clock {
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    spacing: 8

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    Tray {}

                    NetworkControls {}

                    Brightness {}

                    AudioControls {}

                    Battery {}
                }
            }
        }
    }
}
