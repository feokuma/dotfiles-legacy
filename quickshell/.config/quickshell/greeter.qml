//@ pragma IconTheme Adwaita
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Tela de login (greeter) para greetd, construída com Quickshell.
// Este arquivo é auto-contido (não depende de theme/ ou widgets/) para
// poder ser copiado para /etc/greetd/ e executado como usuário "greeter".
//
// O greetd inicia o Hyprland como compositor (ver install-greeter.sh) e este
// arquivo roda via exec-once. O greetd autentica via PAM; este arquivo apenas
// coleta as credenciais e a sessão escolhida, e depois lança a sessão do usuário.

ShellRoot {
    id: root

    readonly property color base:      "#11111b" // Catppuccin Mocha base/crust
    readonly property color surface:   "#1e1e2e"
    readonly property color surface1:  "#313244"
    readonly property color text:      "#cdd6f4"
    readonly property color subtext:   "#a6adc8"
    readonly property color mauve:     "#cba6f7"
    readonly property color lavender:  "#b4befe"
    readonly property color peach:     "#fab387"
    readonly property color red:       "#f38ba8"
    readonly property color green:     "#a6e3a1"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int baseFontSize: 15

    readonly property var userListCommand: ["bash", "-c",
        "awk -F: '$3 >= 1000 && $3 < 60000 {print $1 \" \" $6}' /etc/passwd | sort"]

    property var users: []          // [{name, home}]
    property int selectedUser: 0
    property string password: ""
    property string errorMsg: ""
    property bool authenticating: false
    readonly property bool launching: Greetd.state === GreetdState.ReadyToLaunch
                                      || Greetd.state === GreetdState.Launching
                                      || Greetd.state === GreetdState.Launched
    property string sessionCmd: "start-hyprland" // comando padrão (Hyprland)

    // ------------------------------------------------------------------
    // Listagem de usuários (executado de forma assíncrona)
    // ------------------------------------------------------------------
    Process {
        id: userProcess
        command: userListCommand
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() === "") return
                const parts = line.trim().split(" ")
                const name = parts[0]
                const home = parts.slice(1).join(" ")
                if (home.indexOf("/home/") !== 0) return // só usuários "humanos"
                root.users = root.users.concat([{ name: name, home: home }])
            }
        }
        onExited: {
            // Pré-seleciona o primeiro usuário e dá foco à senha.
            root.selectedUser = 0
            passwordField.forceActiveFocus()
        }
        Component.onCompleted: running = true
    }

    // ------------------------------------------------------------------
    // Fluxo de autenticação com o greetd
    // ------------------------------------------------------------------
    function submitLogin() {
        if (authenticating) return
        if (users.length === 0) return
        if (!Greetd.available) {
            errorMsg = "greetd indisponível (modo preview)"
            return
        }
        // Não envia senha vazia ao PAM: evita falha de autenticação
        // desnecessária (que encerra a conexão com o greetd).
        if (password.length === 0) {
            errorMsg = "Digite a senha"
            passwordField.forceActiveFocus()
            return
        }
        authenticating = true
        errorMsg = ""
        Greetd.createSession(users[selectedUser].name)
    }

    Connections {
        target: Greetd

        // Uma mensagem sem eco é o prompt de senha e recebe a senha digitada.
        // Um prompt com echo pede outra coisa (OTP, usuário, pergunta de um
        // plugin PAM) — respondemos vazio para não vazar informação.
        function onAuthMessage(message, isError, responseRequired, echoResponse) {
            if (responseRequired && !echoResponse) {
                Greetd.respond(root.password)
                return
            }
            if (responseRequired && message)
                root.errorMsg = message
            Greetd.respond("")
        }

        function onAuthFailure(message) {
            root.fail(message || "Senha incorreta")
        }

        function onReadyToLaunch() {
            // Lança a sessão escolhida e encerra o greeter.
            // O greetd inicia a sessão quando o processo do greeter termina.
            Greetd.launch([root.sessionCmd], [], true)
        }

        function onError(error) {
            root.fail(error || "Falha no login")
        }
    }

    // Limpa o estado após falha de autenticação.
    function fail(message) {
        errorMsg = message
        password = ""
        authenticating = false
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession()
        // Devolve o foco ao campo de senha para uma nova tentativa.
        passwordField.forceActiveFocus()
    }

    // ------------------------------------------------------------------
    // Interface
    // ------------------------------------------------------------------
    PanelWindow {
        id: greeterWindow
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        BackgroundEffect.blurRegion: Region {
            x: 0; y: 0
            width: greeterWindow.width; height: greeterWindow.height
        }

        Rectangle {
            anchors.fill: parent
            color: root.base
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    if (authenticating) {
                        Greetd.cancelSession()
                        authenticating = false
                    }
                }
            }

            // Relógio e data (canto superior esquerdo)
            Column {
                anchors {
                    left: parent.left
                    top: parent.top
                    margins: 32
                }
                spacing: 2

                SystemClock {
                    id: systemClock
                    precision: SystemClock.Seconds
                }

                Text {
                    text: Qt.formatDateTime(systemClock.date, "hh:mm AP")
                    color: root.text
                    font.family: root.fontFamily
                    font.pixelSize: 58
                    font.bold: true
                }

                Text {
                    text: Qt.formatDateTime(systemClock.date, "dddd, d MMMM yyyy")
                    color: root.subtext
                    font.family: root.fontFamily
                    font.pixelSize: 20
                }
            }

            // Painel central de login
            Column {
                anchors.centerIn: parent
                spacing: 16
                width: 420

                // Saudação
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Welcome"
                    color: root.text
                    font.family: root.fontFamily
                    font.pixelSize: 26
                    font.bold: true
                }

                // Lista de usuários (clicáveis)
                Column {
                    id: userList
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: root.users

                        Rectangle {
                            required property int index
                            required property var modelData

                            width: 420
                            height: 48
                            radius: 10
                            color: root.selectedUser === index
                                   ? root.mauve
                                   : (userMouse.hovered ? root.surface1 : root.surface)
                            border.width: root.selectedUser === index ? 0 : 1
                            border.color: root.surface1

                            Row {
                                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                spacing: 12

                                Text {
                                    text: "\uf007" // nf-fa-user
                                    color: root.selectedUser === index ? root.base : root.mauve
                                    font.family: root.fontFamily
                                    font.pixelSize: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.name
                                    color: root.selectedUser === index ? root.base : root.text
                                    font.family: root.fontFamily
                                    font.pixelSize: root.baseFontSize + 2
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: userMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.selectedUser = index
                                    passwordField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // Campo de senha
                Rectangle {
                    width: 420
                    height: 48
                    radius: 10
                    color: passwordField.activeFocus ? root.surface1 : root.surface
                    border.width: 1
                    border.color: passwordField.activeFocus ? root.mauve : root.surface1

                    Row {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 8 }
                        spacing: 12

                        Text {
                            text: "\uf023" // nf-fa-lock
                            color: root.mauve
                            font.family: root.fontFamily
                            font.pixelSize: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextField {
                            id: passwordField
                            width: parent.width - 16 - 20 - 12
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.text
                            font.family: root.fontFamily
                            font.pixelSize: root.baseFontSize + 2
                            echoMode: TextInput.Password
                            passwordCharacter: "\u2022"
                            placeholderText: "Password"
                            placeholderTextColor: root.subtext
                            background: null
                            enabled: !root.authenticating && !root.launching
                            // Vinculação bidirecional: captura o texto digitado
                            // em root.password, que é o que se envia ao greetd.
                            text: root.password
                            onTextEdited: root.password = text
                            onAccepted: root.submitLogin()
                        }
                    }
                }

                // Mensagem de erro
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.errorMsg
                    color: root.red
                    font.family: root.fontFamily
                    font.pixelSize: root.baseFontSize
                    visible: root.errorMsg !== ""
                }

                // Botão de login
                Rectangle {
                    width: 420
                    height: 48
                    radius: 10
                    color: (root.authenticating || root.launching) ? root.surface1 : root.green

                    Text {
                        anchors.centerIn: parent
                        text: root.launching ? "Starting session..." : (root.authenticating ? "Authenticating..." : "Sign In")
                        color: (root.authenticating || root.launching) ? root.text : root.base
                        font.family: root.fontFamily
                        font.pixelSize: root.baseFontSize + 2
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.authenticating && !root.launching
                        onClicked: root.submitLogin()
                    }
                }

                // Seletor de sessão
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Text {
                        text: "\uf085" // nf-fa-gear
                        color: root.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Session: " + (root.sessionCmd === "start-hyprland" ? "Hyprland" : root.sessionCmd)
                        color: root.subtext
                        font.family: root.fontFamily
                        font.pixelSize: root.baseFontSize
                    }
                }

                // Botões de energia
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    GreeterActionButton {
                        icon: "\uf021" // nf-fa-refresh
                        label: "Reboot"
                        accent: root.lavender
                        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                    }

                    GreeterActionButton {
                        icon: "\uf011" // nf-fa-power_off
                        label: "Shut Down"
                        accent: root.red
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }
            }
        }
    }

    // Botão de ação (reiniciar / desligar)
    component GreeterActionButton: Item {
        id: buttonRoot
        required property string icon
        required property string label
        property color accent: root.lavender
        signal clicked

        width: 200
        height: 64

        Rectangle {
            id: btnBody
            anchors.fill: parent
            radius: 10
            color: btnMouse.hovered ? root.surface1 : root.surface
            border.width: 1
            border.color: btnMouse.hovered ? buttonRoot.accent : root.surface1

            Text {
                anchors.centerIn: parent
                text: buttonRoot.icon
                color: buttonRoot.accent
                font.family: root.fontFamily
                font.pixelSize: 22
            }

            Text {
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 8
                    horizontalCenter: parent.horizontalCenter
                }
                text: buttonRoot.label
                color: root.text
                font.family: root.fontFamily
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: buttonRoot.clicked()
        }
    }
}
