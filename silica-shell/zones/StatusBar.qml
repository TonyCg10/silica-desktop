import QtQuick
import Quickshell
import Quickshell.Io
import "../menus" as Menus
import "../components" as Components

Item {
    id: root
    required property var panelWindow
    required property int porcentajeBateria
    required property var modelRedes
    required property var modelBrillo
    required property var modelAudioSalidas
    required property var modelAudioEntradas
    required property real volumenActual
    required property bool volumenMute
    required property rect screenGeometry
    required property var modelBluetoothDevices
    required property bool btPowerOn

    width: buttonRow.width
    height: Math.max(50, buttonRow.height + 16)

    property string menuAbierto: ""
    property string menuAnterior: ""
    property bool anyPopupHovered: false

    property bool wifiPowerOn: true
    property var modeloWifiConectado: {
        if (!modelRedes) return "";
        for (var i = 0; i < modelRedes.length; i++) {
            if (modelRedes[i].conectada) return modelRedes[i];
        }
        return "";
    }

    // ── Timers ──
    Timer {
        id: closeTimer
        interval: 200
        onTriggered: { if (!anyPopupHovered) menuAbierto = "" }
    }

    Timer {
        id: openTimer
        interval: 150; repeat: false
        property string pendingMenu: ""
        onTriggered: { menuAbierto = pendingMenu }
    }

    Timer {
        id: hideOldTimer
        interval: 50
        onTriggered: { menuAnterior = "" }
    }

    onMenuAbiertoChanged: {
        if (menuAbierto !== "") {
            hideOldTimer.stop()
            menuAnterior = ""
        } else {
            hideOldTimer.restart()
        }
    }

    // ── Shared helper — wires pill hover events to the shared timers ──
    function pillEntered(key) {
        closeTimer.stop()
        openTimer.pendingMenu = key
        openTimer.start()
    }
    function pillExited() {
        openTimer.stop()
        closeTimer.restart()
    }
    function menuHoverChanged(hovered) {
        anyPopupHovered = hovered
        if (hovered) closeTimer.stop()
        else closeTimer.restart()
    }

    // ── Layout ──
    Row {
        id: buttonRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // ── WiFi ──
        Components.MenuPill {
            id: wifiPill
            menuKey: "wifi"
            menuAbierto: root.menuAbierto
            menuAnterior: root.menuAnterior
            onHoverEntered: root.pillEntered("wifi")
            onHoverExited:  root.pillExited()

            Text {
                text: root.wifiPowerOn ? (root.modeloWifiConectado !== "" ? "\uE0E9E" : "\uE0E9C") : "\uE0E9C"
                color: !root.wifiPowerOn ? "#3b4261" : (root.modeloWifiConectado !== "" ? "#9ece6a" : "#787c99")
                font.pixelSize: 14
                opacity: wifiPill.exp ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 130 } }
                anchors.top: parent.top; anchors.topMargin: (34 - contentHeight) / 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Menus.WiFiMenu {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: 5
                visible: wifiPill.exp; opacity: wifiPill.exp ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                panelWindow: root.panelWindow; screenGeometry: root.screenGeometry
                menuOpen: wifiPill.exp
                onCloseRequested: root.menuAbierto = ""
                onPopupHoverChanged: (h) => root.menuHoverChanged(h)
            }
        }

        // ── Bluetooth ──
        Components.MenuPill {
            id: btPill
            menuKey: "bt"
            menuAbierto: root.menuAbierto
            menuAnterior: root.menuAnterior
            onHoverEntered: root.pillEntered("bt")
            onHoverExited:  root.pillExited()

            Text {
                text: root.btPowerOn ? "\uF0C2F" : "\uF0C30"
                color: root.btPowerOn ? "#7dcfff" : "#3b4261"; font.pixelSize: 14
                opacity: btPill.exp ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 130 } }
                anchors.top: parent.top; anchors.topMargin: (34 - contentHeight) / 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Menus.BluetoothMenu {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: 5
                visible: btPill.exp; opacity: btPill.exp ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                panelWindow: root.panelWindow; screenGeometry: root.screenGeometry
                btPowerOn: root.btPowerOn
                modelBluetoothDevices: root.modelBluetoothDevices
                menuOpen: btPill.exp
                onCloseRequested: root.menuAbierto = ""
                onPopupHoverChanged: (h) => root.menuHoverChanged(h)
            }
        }

        // ── Audio ──
        Components.MenuPill {
            id: audioPill
            menuKey: "audio"
            menuAbierto: root.menuAbierto
            menuAnterior: root.menuAnterior
            onHoverEntered: root.pillEntered("audio")
            onHoverExited:  root.pillExited()

            Text {
                text: root.volumenMute ? "\uF075A" : root.volumenActual > 0.5 ? "\uF0D5A" : root.volumenActual > 0.1 ? "\uF0D56" : "\uF0D52"
                color: "#7aa2f7"; font.pixelSize: 14
                opacity: audioPill.exp ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 130 } }
                anchors.top: parent.top; anchors.topMargin: (34 - contentHeight) / 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Menus.AudioMenu {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: 5
                visible: audioPill.exp; opacity: audioPill.exp ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                panelWindow: root.panelWindow; screenGeometry: root.screenGeometry
                modelSalidas: root.modelAudioSalidas
                modelEntradas: root.modelAudioEntradas
                volumenActual: root.volumenActual
                volumenMute: root.volumenMute
                menuOpen: audioPill.exp
                onCloseRequested: root.menuAbierto = ""
                onPopupHoverChanged: (h) => root.menuHoverChanged(h)
            }
        }

        // ── Brightness ──
        Components.MenuPill {
            id: brilloPill
            menuKey: "brillo"
            menuAbierto: root.menuAbierto
            menuAnterior: root.menuAnterior
            onHoverEntered: root.pillEntered("brillo")
            onHoverExited:  root.pillExited()

            Text {
                text: "\uF0CFF"; color: "#e0af68"; font.pixelSize: 14
                opacity: brilloPill.exp ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 130 } }
                anchors.top: parent.top; anchors.topMargin: (34 - contentHeight) / 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Menus.BrightnessMenu {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: 5
                visible: brilloPill.exp; opacity: brilloPill.exp ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                panelWindow: root.panelWindow; screenGeometry: root.screenGeometry
                modelBrillo: root.modelBrillo
                menuOpen: brilloPill.exp
                onCloseRequested: root.menuAbierto = ""
                onPopupHoverChanged: (h) => root.menuHoverChanged(h)
            }
        }

        // ── Battery ──
        Components.MenuPill {
            id: bateriaPill
            menuKey: "bateria"
            expandedWidth: 280
            menuAbierto: root.menuAbierto
            menuAnterior: root.menuAnterior
            onHoverEntered: root.pillEntered("bateria")
            onHoverExited:  root.pillExited()

            Column {
                spacing: 0
                opacity: bateriaPill.exp ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 130 } }
                anchors.top: parent.top
                anchors.topMargin: (34 - childrenRect.height) / 2
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.porcentajeBateria >= 80 ? "\uF0E4D" : root.porcentajeBateria >= 50 ? "\uF0E4C" : root.porcentajeBateria >= 20 ? "\uF0E4A" : "\uF0E48"
                    color: root.porcentajeBateria <= 15 ? "#f7768e" : "#9ece6a"
                    font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.porcentajeBateria + "%"
                    color: "#787c99"; font.pixelSize: 7; font.bold: true
                }
            }

            Menus.BatteryMenu {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: 5
                visible: bateriaPill.exp; opacity: bateriaPill.exp ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                panelWindow: root.panelWindow; screenGeometry: root.screenGeometry
                porcentajeBateria: root.porcentajeBateria
                menuOpen: bateriaPill.exp
                onCloseRequested: root.menuAbierto = ""
                onPopupHoverChanged: (h) => root.menuHoverChanged(h)
            }
        }
    }
}
