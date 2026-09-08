import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../theme"

PopupWindow {
    id: root

    property var menuHandle: null
    property bool menuOpen: false

    visible: root.menuOpen
    color: "transparent"
    implicitWidth: 230
    implicitHeight: menuList.implicitHeight + 14

    QsMenuOpener {
        id: menuOpener

        menu: root.menuHandle
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.menuOpen
        onCleared: root.menuOpen = false
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        radius: 10
        border.width: 2
        border.color: "#11111b"

        Column {
            id: menuList

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 6
            }
            spacing: 2

            Repeater {
                model: menuOpener.children.values

                delegate: Item {
                    id: entryItem

                    required property var modelData

                    width: menuList.width
                    height: modelData.isSeparator ? 9 : 26

                    // separador
                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: "#45475a"
                    }

                    // item
                    Rectangle {
                        id: entryBody

                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        radius: 6
                        color: mouseArea.hovered && modelData.enabled ? "#313244" : "transparent"

                        Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                margins: 8
                            }
                            spacing: 8

                            Text {
                                id: checkMark

                                width: 14
                                color: "#a6adc8"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                text: {
                                    if (modelData.buttonType === QsMenuButtonType.RadioButton)
                                        return modelData.checkState === Qt.Checked ? "●" : "○";
                                    if (modelData.buttonType === QsMenuButtonType.CheckBox)
                                        return modelData.checkState === Qt.Checked ? "☑" : "☐";
                                    return "";
                                }
                            }

                            Text {
                                width: entryBody.width - checkMark.width - 24
                                text: modelData.text
                                color: modelData.enabled ? "#cdd6f4" : "#6c7086"
                                font.family: Theme.fontFamily
                                font.bold: Theme.fontBold
                                font.pixelSize: Theme.fontSize - 1
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !modelData.isSeparator && modelData.enabled
                        onClicked: {
                            modelData.triggered();
                            root.menuOpen = false;
                        }
                    }
                }
            }
        }
    }
}