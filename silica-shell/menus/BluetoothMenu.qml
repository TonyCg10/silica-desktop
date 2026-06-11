import QtQuick
import QtQuick.Controls
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

    required property bool btPowerOn
    required property var modelBluetoothDevices

    property bool btScanning: btScanProc.running
    property bool btAutoScan: false
    property string btConnectingMAC: ""
    property var btPrevMACs: []
    property bool _destroying: false
    property real lastScanTime: 0

    Component.onDestruction: { _destroying = true }

    ListModel { id: btModel }
    ListModel { id: btNewDevicesModel }

    onModelBluetoothDevicesChanged: syncBtModel()

    onMenuOpenChanged: {
        if (menuOpen) { syncBtModel(); btAutoScanStart() }
    }

    function syncBtModel() {
        var src = modelBluetoothDevices
        if (!src) return
        var i = 0
        while (i < src.length && i < btModel.count) {
            btModel.setProperty(i, "mac", src[i].mac)
            btModel.setProperty(i, "name", src[i].name)
            btModel.setProperty(i, "connected", src[i].connected)
            btModel.setProperty(i, "paired", src[i].paired)
            i++
        }
        while (i < src.length) {
            btModel.append({ mac: src[i].mac, name: src[i].name, connected: src[i].connected, paired: src[i].paired })
            i++
        }
        while (btModel.count > src.length) btModel.remove(btModel.count - 1)

        btNewDevicesModel.clear()
        var prevSet = {}
        for (var p = 0; p < btPrevMACs.length; p++) prevSet[btPrevMACs[p]] = true
        for (var j = 0; j < src.length; j++) {
            if (!prevSet[src[j].mac])
                btNewDevicesModel.append({ mac: src[j].mac, name: src[j].name, connected: src[j].connected, paired: src[j].paired })
        }
    }

    function btRefresh() {
        // Handled in background thread
    }

    function btForceRefresh() {
        btAutoScanStart()
    }

    function btAutoScanStart() {
        let now = Date.now()
        if (now - lastScanTime < 10000) return; 
        lastScanTime = now;

        if (!btPowerOn || btAutoScan) return
        btAutoScan = true
        btScanProc.running = true
    }

    function btTogglePower() {
        btPowerProc.action = btPowerOn ? "off" : "on"
        btPowerProc.running = true
    }

    // Connect, disconnect, and forget commands are one-off triggers
    function btConnect(mac) {
        if (btConnectProc.running) return
        btConnectingMAC = mac
        btConnectProc.mac = mac
        btConnectProc.running = true
    }

    function btDisconnect(mac) {
        btDisconnectProc.mac = mac
        btDisconnectProc.running = true
    }

    function btForget(mac) {
        btRemoveProc.mac = mac
        btRemoveProc.running = true
    }

    Item {
        id: menuContainer
        width: parent.width
        implicitHeight: contentColumn.childrenRect.height
        opacity: root.menuOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: opacity > 0
        
        Rectangle {
            width: parent.width
            implicitHeight: parent.implicitHeight
            radius: 12
            color: "#1f2335"
            border.color: "#2f334d"; border.width: 1
            clip: true
            focus: true
            Keys.onEscapePressed: root.closeRequested()

            Flickable {
                width: parent.width
                height: contentHeight
                contentHeight: contentColumn.height
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: contentColumn
                    width: parent.width; spacing: 0

                    Item { width: 1; height: 12; implicitHeight: 12 }
                    Components.SectionHeader {
                        icon: Components.IconSystem.bluetooth.on
                        iconColor: "#ffffff"
                        title: "Bluetooth"

                        Components.ToggleSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: btPowerOn
                            onToggled: btTogglePower()
                        }

                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: refreshBt.containsMouse ? "#2f334d" : "transparent"
                            border.color: refreshBt.containsMouse ? "#3b4261" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Components.SpinnerIcon {
                                anchors.centerIn: parent
                                spinning: btScanning
                                activeColor: "#ffffff"
                                idleColor: "#ffffff"
                                size: 12
                            }
                            MouseArea { id: refreshBt; anchors.fill: parent; hoverEnabled: true; onClicked: btForceRefresh() }
                        }
                    }
                    Item { width: 1; height: 12; implicitHeight: 12 }
                    Components.Separator { margins: 16 }
                    Item { width: 1; height: 8; implicitHeight: 8 }

                    // New devices
                    Repeater {
                        model: btNewDevicesModel
                        delegate: Rectangle {
                            required property string mac
                            required property string name
                            required property bool connected
                            required property bool paired
                            width: contentColumn.width; height: 40; implicitHeight: 40; radius: 8
                            color: "#7aa2f711"; border.color: "#7aa2f7"; border.width: 1

                            Row { x: 12; spacing: 8; anchors.verticalCenter: parent.verticalCenter
                                Text { text: Components.IconSystem.bluetooth.on; color: "#ffffff"; font.pixelSize: 14; font.family: Components.IconSystem.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                                Column { anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                    Text { text: name; color: "#c0caf5"; font.pixelSize: 12; font.bold: true }
                                    Text { text: "Nuevo dispositivo"; color: "#7aa2f7"; font.pixelSize: 10 }
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right; anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28; height: 28; radius: 14
                                color: "#7aa2f7"
                                Text { anchors.centerIn: parent; text: Components.IconSystem.action.connect; color: "#ffffff"; font.pixelSize: 12; font.family: Components.IconSystem.fontFamily }
                                MouseArea { anchors.fill: parent; onClicked: btConnect(mac) }
                            }
                        }
                    }

                    // Paired/known devices
                    Repeater {
                        model: btModel
                        delegate: Rectangle {
                            required property string mac
                            required property string name
                            required property bool connected
                            required property bool paired
                            width: contentColumn.width; height: 36; implicitHeight: 36; radius: 6
                            color: devMa.containsMouse ? "#24283b" : "transparent"

                            MouseArea { id: devMa; anchors.fill: parent; hoverEnabled: true }

                            Row { x: 12; spacing: 8; anchors.verticalCenter: parent.verticalCenter
                                Text { text: connected ? Components.IconSystem.bluetooth.connected : Components.IconSystem.bluetooth.disconnected; color: "#ffffff"; font.pixelSize: 14; font.family: Components.IconSystem.fontFamily }
                                Column { anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                    Text { text: name; color: connected ? "#c0caf5" : "#787c99"; font.pixelSize: 12; font.bold: connected }
                                    Text { text: connected ? "Conectado" : (paired ? "Emparejado" : mac); color: "#565f89"; font.pixelSize: 10 }
                                }
                            }

                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Rectangle {
                                    visible: connected
                                    width: 24; height: 24; radius: 12
                                    color: discBt.containsMouse ? "#f7768e33" : "transparent"
                                    Text { anchors.centerIn: parent; text: Components.IconSystem.action.disconnect; color: "#ffffff"; font.pixelSize: 11; font.family: Components.IconSystem.fontFamily }
                                    MouseArea { id: discBt; anchors.fill: parent; hoverEnabled: true; onClicked: btDisconnect(mac) }
                                }

                                Rectangle {
                                    visible: !connected
                                    width: 24; height: 24; radius: 12
                                    color: btConnectingMAC === mac ? "transparent" : (connBt.containsMouse ? "#9ece6a33" : "transparent")
                                    Item {
                                        anchors.centerIn: parent; width: 14; height: 14
                                        Components.SpinnerIcon {
                                            anchors.centerIn: parent
                                            spinning: btConnectingMAC === mac
                                            visible: btConnectingMAC === mac
                                            activeColor: "#9ece6a"
                                            size: 11
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: Components.IconSystem.action.connect
                                            color: "#ffffff"; font.pixelSize: 11
                                            font.family: Components.IconSystem.fontFamily
                                            visible: btConnectingMAC !== mac
                                        }
                                    }
                                    MouseArea { id: connBt; anchors.fill: parent; hoverEnabled: true; onClicked: btConnect(mac) }
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: forgetBt.containsMouse ? "#f7768e33" : "transparent"
                                    Text { anchors.centerIn: parent; text: Components.IconSystem.action.forget; color: "#ffffff"; font.pixelSize: 11; font.family: Components.IconSystem.fontFamily }
                                    MouseArea { id: forgetBt; anchors.fill: parent; hoverEnabled: true; onClicked: btForget(mac) }
                                }
                            }
                        }
                    }

                    Item {
                        visible: btModel.count === 0 && btPowerOn && !btScanning
                        width: parent.width; height: 60; implicitHeight: 60
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: Components.IconSystem.bluetooth.on; color: "#ffffff"; font.pixelSize: 20; font.family: Components.IconSystem.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Sin dispositivos"; color: "#ffffff"; font.pixelSize: 11 }
                        }
                    }

                    Item {
                        visible: !btPowerOn
                        width: parent.width; height: 60; implicitHeight: 60
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: Components.IconSystem.bluetooth.on; color: "#ffffff"; font.pixelSize: 20; font.family: Components.IconSystem.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Bluetooth apagado"; color: "#565f89"; font.pixelSize: 11 }
                        }
                    }

                    Item { width: 1; height: 8; implicitHeight: 8 }
                }
            }
        }

        Process { id: btPowerProc; property string action: "on"
            command: ["bash", "-c", action === "on" ? "rfkill unblock bluetooth" : "rfkill block bluetooth"]
        }

        Process { id: btScanProc
            command: ["bluetoothctl", "--timeout", "7", "scan", "on"]
            onRunningChanged: { if (!running && !_destroying) { btAutoScan = false } }
        }

        Process { id: btConnectProc; property string mac: ""
            command: ["bluetoothctl", "connect", mac]
            onRunningChanged: { if (!running && !_destroying && mac !== "") { btConnectingMAC = "" } }
        }

        Process { id: btDisconnectProc; property string mac: ""
            command: ["bluetoothctl", "disconnect", mac]
        }

        Process { id: btRemoveProc; property string mac: ""
            command: ["bluetoothctl", "remove", mac]
        }
    }
}
