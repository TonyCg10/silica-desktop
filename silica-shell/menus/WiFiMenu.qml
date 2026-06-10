import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell._Window
import "../components" as Components

Item {
    id: root
    implicitHeight: menuContainer.childrenRect.height
    required property var panelWindow
    required property rect screenGeometry
    property bool menuOpen: false
    signal closeRequested()
    signal popupHoverChanged(bool hovered)

    property string wifiView: "list"
    property string wifiSelectedSSID: ""
    property string wifiSelectedSecurity: ""
    property int wifiSelectedSignal: 0
    property string wifiPassword: ""
    property bool wifiShowPassword: false
    property string wifiConnectingSSID: ""
    property bool wifiPowerOn: true
    property bool _destroying: false
    property real lastRefreshTime: 0

    Component.onDestruction: { _destroying = true }

    function iconoWifi(intensidad) {
        if (intensidad >= 75) return "\uF0E9E"
        if (intensidad >= 50) return "\uF0E96"
        if (intensidad >= 25) return "\uF0E8D"
        return "\uF0929"
    }

    property var modeloWifiConectado: {
        for (var i = 0; i < wifiModel.count; i++) {
            var item = wifiModel.get(i)
            if (item.conectada) return item
        }
        return ""
    }

    function wifiConectar(ssid, password) {
        if (cmdConectarOpen.running || cmdConectarPass.running) return
        wifiConnectingSSID = ssid
        if (password !== "") {
            cmdConectarPass.ssid = ssid
            cmdConectarPass.clave = password
            cmdConectarPass.running = true
        } else {
            cmdConectarOpen.ssid = ssid
            cmdConectarOpen.running = true
        }
    }

    function wifiRefrescar() {
        if (!wifiPowerOn) return
        if (!wifiScanProc.running) wifiScanProc.running = true
    }

    function wifiForceRescan() {
        let now = Date.now()
        if (now - lastRefreshTime < 10000) return; 
        lastRefreshTime = now;

        if (!wifiPowerOn) return
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"])
        if (!wifiScanProc.running) wifiScanProc.running = true
    }

    function wifiDesconectar() {
        var conn = modeloWifiConectado
        if (conn && conn !== "") {
            cmdDesconectar.ssid = conn.ssid
            cmdDesconectar.running = true
        }
    }

    function wifiTogglePower() {
        cmdWifiPower.action = wifiPowerOn ? "off" : "on"
        cmdWifiPower.running = true
    }

    function connectWifi() {
        if (wifiPassword.length > 0 && wifiConnectingSSID === "") {
            wifiConectar(wifiSelectedSSID, wifiPassword)
        }
    }

    onMenuOpenChanged: {
        if (menuOpen) wifiRefrescar()
    }

    // ── WIFI MENU (inline in MenuPill) ──
    Item {
        id: menuContainer
        width: parent.width
        implicitHeight: wifiListColumn.childrenRect.height
        opacity: root.menuOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: opacity > 0
        
        Rectangle {
            width: parent.width
            implicitHeight: parent.implicitHeight
            radius: 12
            color: "transparent"
            clip: true

            Flickable {
                width: parent.width
                height: contentHeight
                contentHeight: wifiListColumn.height
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: wifiListColumn
                    width: parent.width; spacing: 0

                    Item { width: 1; height: 12; implicitHeight: 12 }
                    Components.SectionHeader {
                        icon: "\uF0E9E"
                        title: "Wi-Fi"

                        Components.ToggleSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: wifiPowerOn
                            onToggled: wifiTogglePower()
                        }

                        Rectangle {
                            id: wifiRefreshBtn
                            width: 24; height: 24; radius: 12
                            color: rh.containsMouse ? "#2f334d" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Components.SpinnerIcon {
                                anchors.centerIn: parent
                                spinning: wifiScanProc.running
                                activeColor: "#9ece6a"
                                idleColor: "#7aa2f7"
                                size: 11
                            }
                            MouseArea { id: rh; anchors.fill: parent; hoverEnabled: true; onClicked: wifiForceRescan() }
                        }
                    }
                    Item { width: 1; height: 8; implicitHeight: 8 }
                    Components.Separator { margins: 12 }
                    Item { width: 1; height: 6; implicitHeight: 6 }

                    Repeater {
                        model: wifiModel
                        delegate: Rectangle {
                            required property string ssid
                            required property int intensidad
                            required property bool protegida
                            required property bool conectada
                            width: parent.width; height: 32; implicitHeight: 32; radius: 6
                            color: mw.containsMouse ? "#24283b" : "transparent"

                            MouseArea {
                                id: mw; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (wifiConnectingSSID !== "") return
                                    wifiSelectedSSID = ssid
                                    wifiSelectedSecurity = protegida ? "WPA2" : "Abierta"
                                    wifiSelectedSignal = intensidad
                                    wifiPassword = ""
                                    wifiView = "info"
                                }
                            }

                            Row { x: 10; spacing: 8; anchors.verticalCenter: parent.verticalCenter
                                Text { text: iconoWifi(intensidad); color: modeloWifiConectado && modeloWifiConectado.ssid === ssid ? "#9ece6a" : "#787c99"; font.pixelSize: 12 }
                                Text { text: ssid; color: modeloWifiConectado && modeloWifiConectado.ssid === ssid ? "#c0caf5" : "#787c99"; font.pixelSize: 12; font.bold: modeloWifiConectado && modeloWifiConectado.ssid === ssid }
                                Item { width: 1; height: 1 }
                                Text { text: protegida ? "\uF023" : ""; color: "#565f89"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: conectada ? "\u25CF" : ""; color: "#9ece6a"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }

                    Item {
                        visible: wifiModel.count === 0 && wifiPowerOn
                        width: parent.width; height: 60; implicitHeight: 60
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "\uF0E9C"; color: "#565f89"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Sin redes"; color: "#565f89"; font.pixelSize: 11 }
                        }
                    }

                    Item {
                        visible: !wifiPowerOn
                        width: parent.width; height: 60; implicitHeight: 60
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "\uF0E9C"; color: "#565f89"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Wi-Fi apagado"; color: "#565f89"; font.pixelSize: 11 }
                        }
                    }

                    Item { width: 1; height: 8; implicitHeight: 8 }
                }
            }
        }

        Process { id: cmdConectarOpen; property string ssid: ""
            command: ["nmcli", "device", "wifi", "connect", ssid]
            onRunningChanged: { if (!running && !_destroying && ssid !== "") { wifiConnectingSSID = ""; wifiView = "list"; wifiRefrescar() } }
        }
        Process { id: cmdConectarPass; property string ssid: ""; property string clave: ""
            command: ["nmcli", "device", "wifi", "connect", ssid, "password", clave]
            onRunningChanged: { if (!running && !_destroying && ssid !== "") { wifiConnectingSSID = ""; wifiPassword = ""; wifiView = "list"; wifiRefrescar() } }
        }
        Process { id: cmdDesconectar; property string ssid: ""
            command: ["bash", "-c", "dev=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | grep ':wifi$' | head -1 | cut -d: -f1); nmcli device disconnect \"$dev\" 2>/dev/null || nmcli connection down id \"$ssid\" 2>/dev/null"]
            onRunningChanged: { if (!running && !_destroying && ssid !== "") wifiRefrescar() }
        }
        Process { id: cmdWifiPower; property string action: "on"
            command: ["nmcli", "radio", "wifi", action]
            onRunningChanged: { if (!running && !_destroying) { wifiPowerOn = (action === "on"); if (wifiPowerOn) wifiRefrescar() } }
        }
    }

    // ── WIFI CONNECT DIALOG (FloatingWindow, closeable with Escape only) ──
    FloatingWindow {
        id: wifiConnectDialog
        visible: root.wifiView === "info"
        implicitWidth: 300
        implicitHeight: 240
        color: "#1f2335"
        title: "wifi-dialog"

        onVisibleChanged: {
            if (!visible) { wifiPassword = ""; wifiConnectingSSID = ""; wifiSelectedSSID = "" }
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "transparent"
            border.color: "#2f334d"; border.width: 1
            clip: true
            focus: true

            Keys.onEscapePressed: {
                root.wifiView = "list"
                root.wifiPassword = ""
                root.wifiConnectingSSID = ""
                root.wifiSelectedSSID = ""
            }

            Item { width: 1; height: 12; implicitHeight: 12 }
            Row { x: 12; spacing: 8
                Rectangle {
                    width: 22; height: 22; radius: 11
                    color: "transparent"
                    Text { anchors.centerIn: parent; text: "\uF02E2"; color: "#7aa2f7"; font.pixelSize: 11 }
                }
                Text { text: wifiSelectedSSID; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: 220 }
            }
            Item { width: 1; height: 8; implicitHeight: 8 }
            Components.Separator { margins: 12 }
            Item { width: 1; height: 8; implicitHeight: 8 }

            Row { x: 12; spacing: 6
                Text { text: iconoWifi(wifiSelectedSignal); color: "#7aa2f7"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: wifiSelectedSignal + "%"; color: "#c0caf5"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            }
            Item { width: 1; height: 6; implicitHeight: 6 }
            Row { x: 12; spacing: 6
                Text { text: "\uF023"; color: "#565f89"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Text { text: wifiSelectedSecurity; color: "#787c99"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            }
            Item { width: 1; height: 10 }
            Components.Separator { margins: 12 }
            Item { width: 1; height: 10 }

            Rectangle {
                visible: modeloWifiConectado !== "" && modeloWifiConectado.ssid === wifiSelectedSSID
                x: 12; width: parent.width - 24; height: 32; radius: 6
                color: "#f7768e22"; border.color: "#f7768e"; border.width: 1
                Row { x: 10; spacing: 6; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "\uF0344"; color: "#f7768e"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Desconectar"; color: "#f7768e"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true
                    onClicked: { wifiDesconectar() }
                }
            }
            Item { visible: modeloWifiConectado !== "" && modeloWifiConectado.ssid === wifiSelectedSSID; width: 1; height: 8 }

            Column {
                visible: wifiSelectedSecurity !== "Abierta" && (modeloWifiConectado === "" || modeloWifiConectado.ssid !== wifiSelectedSSID)
                width: parent.width; spacing: 0

                Rectangle {
                    x: 12; width: parent.width - 24; height: 32; radius: 6
                    color: "#24283b"; border.color: "#2f334d"; border.width: 1
                    TextField {
                        id: passwordInput
                        anchors.fill: parent
                        color: "#c0caf5"
                        placeholderText: "Contraseña..."
                        placeholderTextColor: "#565f89"
                        echoMode: wifiShowPassword ? TextInput.Normal : TextInput.Password
                        onTextChanged: wifiPassword = text
                        background: null
                        font.pixelSize: 11
                        leftPadding: 10; rightPadding: 32
                        selectByMouse: true
                        Keys.onReturnPressed: connectWifi()
                        Keys.onEnterPressed: connectWifi()
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22; radius: 11
                        color: tb.containsMouse ? "#2f334d" : "transparent"
                        Text { anchors.centerIn: parent; text: wifiShowPassword ? "\uF06E6" : "\uF06E2"; color: "#7aa2f7"; font.pixelSize: 11 }
                        MouseArea { id: tb; anchors.fill: parent; hoverEnabled: true; onClicked: wifiShowPassword = !wifiShowPassword }
                    }
                }
                Item { width: 1; height: 8; implicitHeight: 8 }

                Rectangle {
                    x: 12; width: parent.width - 24; height: 32; radius: 6
                    color: "#7aa2f7"; opacity: enabled ? 1 : 0.5
                    enabled: wifiPassword.length > 0 && wifiConnectingSSID === ""
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Components.SpinnerIcon {
                            visible: wifiConnectingSSID !== ""
                            spinning: wifiConnectingSSID !== ""
                            idleColor: "#1f2335"; activeColor: "#1f2335"
                            size: 12
                        }
                        Text {
                            text: wifiConnectingSSID !== "" ? "Conectando..." : "Conectar"
                            color: "#1f2335"; font.pixelSize: 12; font.bold: true
                        }
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: connectWifi() }
                }
            }

            Rectangle {
                visible: wifiSelectedSecurity === "Abierta" && (modeloWifiConectado === "" || modeloWifiConectado.ssid !== wifiSelectedSSID)
                x: 12; width: parent.width - 24; height: 32; radius: 6
                color: "#7aa2f7"
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Components.SpinnerIcon {
                        visible: wifiConnectingSSID !== ""
                        spinning: wifiConnectingSSID !== ""
                        idleColor: "#1f2335"; activeColor: "#1f2335"
                        size: 12
                    }
                    Text {
                        text: wifiConnectingSSID !== "" ? "Conectando..." : "Conectar"
                        color: "#1f2335"; font.pixelSize: 12; font.bold: true
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: { if (wifiConnectingSSID === "") wifiConectar(wifiSelectedSSID, "") }
                }
            }
            Item { width: 1; height: 10 }
        }
    }

    // ── MODEL ──
    ListModel { id: wifiModel }

    Process { id: wifiScanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        property var seen: ({})
        stdout: SplitParser {
            onRead: (line) => {
                if (line.length === 0) return
                var partes = line.split(":")
                if (partes.length < 1 || partes[0].length === 0) return
                var ssid = partes[0]
                if (ssid === "--" || ssid === "") return
                var intensidad = parseInt(partes[1] || "0")
                var protegida = partes.length >= 3 && partes[2].length > 0 && partes[2] !== "--"
                var conectada = partes.length >= 4 && partes[3] === "*"
                if (wifiScanProc.seen[ssid] !== undefined) {
                    if (conectada) wifiModel.setProperty(wifiScanProc.seen[ssid], "conectada", true)
                    return
                }
                wifiScanProc.seen[ssid] = wifiModel.count
                wifiModel.append({ ssid: ssid, intensidad: intensidad, protegida: protegida, conectada: conectada })
            }
        }
        onRunningChanged: { if (running) { wifiModel.clear(); seen = {} } }
    }
}
