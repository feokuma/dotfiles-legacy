//@ pragma IconTheme Adwaita
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "widgets"
import "widgets/network"
import "widgets/audio"

// Barra personalizada adaptada de ~/Downloads/dotfiles/quickshell
// (.config/quickshell/shell.qml), empacotada como plugin de barra do
// omarchy-shell (kind: "bar"). Ativada com:
//   omarchy bar use feokuma.dotfiles-bar
// Revertida com:
//   omarchy bar use omarchy.bar
Item {
    id: root

    // ------------------------------------------------------------- host API
    //
    // O host (shell.qml do omarchy-shell) lê estas propriedades para ancorar
    // notificações/OSD/popups em relação à barra ativa.

    property string position: "top"
    property bool vertical: false
    readonly property int barSize: 40
    property bool barHidden: false
    property string fontFamily: "JetBrainsMono Nerd Font"

    // Propriedades que o host injeta em barras (mantidas inertes aqui; esta
    // barra não usa o layout do shell.json — o layout é fixo, como no
    // dotfiles original).
    property string omarchyPath: Quickshell.env("OMARCHY_PATH")
    property var barWidgetRegistry: null
    property var pluginRegistry: null
    property var barConfig: ({})
    property var shell: null
    property var manifest: null

    // ------------------------------------------------------- bar-off toggle
    //
    // Espelha o flag `bar-off` criado por `omarchy toggle bar`, como faz a
    // barra built-in: a barra escondida é estacionada fora da tela e perde a
    // zona de exclusão.

    property string home: Quickshell.env("HOME")

    Process {
        id: barHiddenProbe

        running: true
        command: ["bash", "-c", "[[ -f $HOME/.local/state/omarchy/toggles/bar-off ]] && echo yes || echo no"]
        stdout: SplitParser {
            onRead: function(line) {
                root.barHidden = String(line).trim() === "yes";
            }
        }
    }

    FileView {
        path: root.home + "/.local/state/omarchy/toggles"
        watchChanges: true
        printErrors: false
        onFileChanged: barHiddenProbe.running = true
    }

    // ---------------------------------------------------------------- panels
    //
    // Uma barra por monitor (o dotfiles original criava só na tela primária;
    // aqui seguimos o padrão da barra built-in do Omarchy).

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: bar

                required property var modelData
                screen: modelData

                color: "transparent"

                exclusionMode: root.barHidden ? ExclusionMode.Ignore : ExclusionMode.Auto

                margins {
                    top: root.barHidden ? -root.barSize : 0
                }

                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: root.barSize

                WlrLayershell.namespace: "feokuma-dotfiles-bar"

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
    }
}
