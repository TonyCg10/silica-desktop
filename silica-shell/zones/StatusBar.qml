import QtQuick
import Quickshell
import Quickshell.Io
import "../menus" as Menus

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

    width: buttonRow.width
    height: 50

    property string menuAbierto: ""
    property bool anyPopupHovered: false

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: {
            if (!anyPopupHovered)
                menuAbierto = ""
        }
    }

    Row {
        id: buttonRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            width: 34; height: 34; radius: 17
            color: menuAbierto === "wifi" ? "#24283b" : "#1f2335"; border.color: "#2f334d"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: wifiMenu.wifiPowerOn ? (wifiMenu.modeloWifiConectado !== "" ? "\uF0E9E" : "\uF0E9C") : "\uF0E9C"
                color: !wifiMenu.wifiPowerOn ? "#3b4261" : (wifiMenu.modeloWifiConectado !== "" ? "#9ece6a" : "#787c99")
                font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: { closeTimer.stop(); root.menuAbierto = "wifi" }
                onExited: closeTimer.restart()
            }
        }

        Rectangle {
            width: 34; height: 34; radius: 17
            color: menuAbierto === "bluetooth" ? "#24283b" : "#1f2335"; border.color: "#2f334d"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: btMenu.btPowerOn ? "\uF0C2F" : "\uF0C30"
                color: btMenu.btPowerOn ? "#7dcfff" : "#3b4261"; font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: { closeTimer.stop(); root.menuAbierto = "bluetooth" }
                onExited: closeTimer.restart()
            }
        }

        Rectangle {
            width: 34; height: 34; radius: 17
            color: menuAbierto === "audio" ? "#24283b" : "#1f2335"; border.color: "#2f334d"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: root.volumenMute ? "\uF0D59" : root.volumenActual > 0.5 ? "\uF0D5A" : root.volumenActual > 0.1 ? "\uF0D58" : "\uF0D57"
                color: "#7aa2f7"; font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: { closeTimer.stop(); root.menuAbierto = "audio" }
                onExited: closeTimer.restart()
            }
        }

        Rectangle {
            width: 34; height: 34; radius: 17
            color: menuAbierto === "brillo" ? "#24283b" : "#1f2335"; border.color: "#2f334d"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: "\uF0CFF"
                color: "#e0af68"; font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: { closeTimer.stop(); root.menuAbierto = "brillo" }
                onExited: closeTimer.restart()
            }
        }

        Rectangle {
            width: 34; height: 34; radius: 17
            color: menuAbierto === "bateria" ? "#24283b" : "#1f2335"; border.color: "#2f334d"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: root.porcentajeBateria >= 80 ? "\uF0E4D" : root.porcentajeBateria >= 50 ? "\uF0E4C" : root.porcentajeBateria >= 20 ? "\uF0E4A" : "\uF0E48"
                color: root.porcentajeBateria <= 15 ? "#f7768e" : "#9ece6a"
                font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: { closeTimer.stop(); root.menuAbierto = "bateria" }
                onExited: closeTimer.restart()
            }
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.porcentajeBateria + "%"
                color: "#787c99"; font.pixelSize: 7; font.bold: true
            }
        }
    }

    Menus.WiFiMenu {
        id: wifiMenu
        panelWindow: root.panelWindow
        screenGeometry: root.screenGeometry
        menuOpen: root.menuAbierto === "wifi"
        onCloseRequested: root.menuAbierto = ""
        onPopupHoverChanged: function(hovered) {
            root.anyPopupHovered = hovered
            if (hovered) closeTimer.stop()
            else closeTimer.restart()
        }
    }

    Menus.BluetoothMenu {
        id: btMenu
        panelWindow: root.panelWindow
        screenGeometry: root.screenGeometry
        menuOpen: root.menuAbierto === "bluetooth"
        onCloseRequested: root.menuAbierto = ""
        onPopupHoverChanged: function(hovered) {
            root.anyPopupHovered = hovered
            if (hovered) closeTimer.stop()
            else closeTimer.restart()
        }
    }

    Menus.AudioMenu {
        id: audioMenu
        panelWindow: root.panelWindow
        screenGeometry: root.screenGeometry
        modelSalidas: root.modelAudioSalidas
        modelEntradas: root.modelAudioEntradas
        volumenActual: root.volumenActual
        volumenMute: root.volumenMute
        menuOpen: root.menuAbierto === "audio"
        onCloseRequested: root.menuAbierto = ""
        onPopupHoverChanged: function(hovered) {
            root.anyPopupHovered = hovered
            if (hovered) closeTimer.stop()
            else closeTimer.restart()
        }
    }

    Menus.BrightnessMenu {
        id: brilloMenu
        panelWindow: root.panelWindow
        screenGeometry: root.screenGeometry
        modelBrillo: root.modelBrillo
        menuOpen: root.menuAbierto === "brillo"
        onCloseRequested: root.menuAbierto = ""
        onPopupHoverChanged: function(hovered) {
            root.anyPopupHovered = hovered
            if (hovered) closeTimer.stop()
            else closeTimer.restart()
        }
    }

    Menus.BatteryMenu {
        id: batteryMenu
        panelWindow: root.panelWindow
        screenGeometry: root.screenGeometry
        porcentajeBateria: root.porcentajeBateria
        menuOpen: root.menuAbierto === "bateria"
        onCloseRequested: root.menuAbierto = ""
        onPopupHoverChanged: function(hovered) {
            root.anyPopupHovered = hovered
            if (hovered) closeTimer.stop()
            else closeTimer.restart()
        }
    }
}
