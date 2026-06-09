import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell._Window

Item {
    id: root
    required property var panelWindow
    required property rect screenGeometry
    property bool menuOpen: false
    signal closeRequested()
    signal popupHoverChanged(bool hovered)

    property bool btPowerOn: true
    property bool btScanning: false
    property bool btAutoScan: false
    property string btConnectingMAC: ""
    property var btDeviceCache: []
    property bool btRefreshAborted: false
    property var btPrevMACs: []
    ListModel { id: btModel }
    ListModel { id: btNewDevicesModel }

    onMenuOpenChanged: {
        if (menuOpen) { btRefresh(); btAutoScanStart() }
    }

    function syncBtModel() {
        var src = btDeviceCache
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
        if (!btPowerOn || btRefreshProc.running) return
        btRefreshProc.running = true
    }

    function btForceRefresh() {
        btDeviceCache = []
        if (btRefreshProc.running) { btRefreshAborted = true; btRefreshProc.running = false }
        btRefresh()
    }

    function btAutoScanStart() {
        if (!btPowerOn || btAutoScan) return
        btAutoScan = true
        btScanProc.running = true
    }

    function btTogglePower() {
        btPowerProc.action = btPowerOn ? "off" : "on"
        btPowerProc.running = true
    }

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

    PopupWindow {
        id: btMenu
        anchor.window: panelWindow
        implicitWidth: 320
        implicitHeight: 420
        visible: root.menuOpen === true
        color: "transparent"
        anchor.rect.x: screenGeometry.width - width - 24
        anchor.rect.y: 54

        HoverHandler { onHoveredChanged: root.popupHoverChanged(hovered) }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "#1f2335"
            border.color: "#2f334d"; border.width: 1
            clip: true
            focus: true
            Keys.onEscapePressed: root.closeRequested()

            Flickable {
                anchors.fill: parent
                contentHeight: contentColumn.height
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: contentColumn
                    width: parent.width; spacing: 0

                    Item { width: 1; height: 12 }
                    Row { x: 16; spacing: 10
                        Text { text: "\uF0C2F"; color: "#7aa2f7"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Bluetooth"; color: "#c0caf5"; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }

                        Rectangle {
                            width: 40; height: 22; radius: 11
                            color: btPowerOn ? "#7dcfff" : "#2f334d"
                            border.color: btPowerOn ? "#89dceb" : "#3b4261"; border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                x: btPowerOn ? 20 : 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: 9; color: "#c0caf5"
                                Behavior on x { NumberAnimation { duration: 120 } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: btTogglePower() }
                        }

                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: refreshBt.containsMouse ? "#2f334d" : "transparent"
                            border.color: refreshBt.containsMouse ? "#3b4261" : "transparent"
                            Text { anchors.centerIn: parent; text: btScanning ? "\uF0453" : "\uF0452"; color: "#7dcfff"; font.pixelSize: 12; rotation: btScanning ? 0 : 0 }
                            MouseArea { id: refreshBt; anchors.fill: parent; hoverEnabled: true; onClicked: btForceRefresh() }
                        }
                    }
                    Item { width: 1; height: 12 }
                    Rectangle { width: parent.width - 32; height: 1; x: 16; color: "#2f334d" }
                    Item { width: 1; height: 8 }

                    // New devices
                    Repeater {
                        model: btNewDevicesModel
                        delegate: Rectangle {
                            required property string mac
                            required property string name
                            required property bool connected
                            required property bool paired
                            width: contentColumn.width; height: 40; radius: 8
                            color: "#7aa2f711"; border.color: "#7aa2f7"; border.width: 1

                            Row { x: 12; spacing: 8; anchors.verticalCenter: parent.verticalCenter
                                Text { text: "\uF0C2F"; color: "#7aa2f7"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
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
                                Text { anchors.centerIn: parent; text: "\uF0647"; color: "#1f2335"; font.pixelSize: 12 }
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
                            width: contentColumn.width; height: 36; radius: 6
                            color: devMa.containsMouse ? "#24283b" : "transparent"

                            MouseArea { id: devMa; anchors.fill: parent; hoverEnabled: true }

                            Row { x: 12; spacing: 8; anchors.verticalCenter: parent.verticalCenter
                                Text { text: connected ? "\uF0C2F" : "\uF0C30"; color: connected ? "#9ece6a" : "#787c99"; font.pixelSize: 14 }
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
                                    Text { anchors.centerIn: parent; text: "\uF0344"; color: "#f7768e"; font.pixelSize: 11 }
                                    MouseArea { id: discBt; anchors.fill: parent; hoverEnabled: true; onClicked: btDisconnect(mac) }
                                }

                                Rectangle {
                                    visible: !connected
                                    width: 24; height: 24; radius: 12
                                    color: connBt.containsMouse ? "#9ece6a33" : "transparent"
                                    Text { anchors.centerIn: parent; text: "\uF0647"; color: "#9ece6a"; font.pixelSize: 11 }
                                    MouseArea { id: connBt; anchors.fill: parent; hoverEnabled: true; onClicked: btConnect(mac) }
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: forgetBt.containsMouse ? "#f7768e33" : "transparent"
                                    Text { anchors.centerIn: parent; text: "\uF05E6"; color: "#f7768e"; font.pixelSize: 11 }
                                    MouseArea { id: forgetBt; anchors.fill: parent; hoverEnabled: true; onClicked: btForget(mac) }
                                }
                            }
                        }
                    }

                    Item {
                        visible: btModel.count === 0 && btPowerOn && !btScanning
                        width: parent.width; height: 60
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "\uF0C30"; color: "#565f89"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Sin dispositivos"; color: "#565f89"; font.pixelSize: 11 }
                        }
                    }

                    Item {
                        visible: !btPowerOn
                        width: parent.width; height: 60
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "\uF0C30"; color: "#565f89"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Bluetooth apagado"; color: "#565f89"; font.pixelSize: 11 }
                        }
                    }

                    Item { width: 1; height: 8 }
                }
            }
        }

        Process { id: btRefreshProc
            command: ["bash", "-c", "bluetoothctl devices | while IFS= read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); info=$(bluetoothctl info \"$mac\" 2>/dev/null); connected=$(echo \"$info\" | grep 'Connected: yes' | wc -l); paired=$(echo \"$info\" | grep 'Paired: yes' | wc -l); echo \"$mac|$name|$connected|$paired\"; done"]
            property string output: ""
            stdout: SplitParser {
                onRead: (line) => {
                    if (line.length === 0) return
                    var parts = line.split("|")
                    if (parts.length < 4) return
                    root.btDeviceCache.push({ mac: parts[0], name: parts[1], connected: parts[2] === "1", paired: parts[3] === "1" })
                }
            }
            onRunningChanged: {
                if (!running) {
                    root.syncBtModel()
                    root.btRefreshAborted = false
                } else {
                    root.btDeviceCache = []
                }
            }
        }

        Process { id: btPowerProc; property string action: "on"
            command: ["bash", "-c", action === "on" ? "rfkill unblock bluetooth" : "rfkill block bluetooth"]
            onRunningChanged: { if (!running) { btPowerOn = (action === "on"); if (btPowerOn) btRefresh() } }
        }

        Process { id: btScanProc
            command: ["bluetoothctl", "--timeout", "7", "scan", "on"]
            onRunningChanged: { if (!running) { btScanning = false; btAutoScan = false; btRefresh() } }
        }

        Process { id: btConnectProc; property string mac: ""
            command: ["bluetoothctl", "connect", mac]
            onRunningChanged: { if (!running && mac !== "") { btConnectingMAC = ""; btRefresh() } }
        }

        Process { id: btDisconnectProc; property string mac: ""
            command: ["bluetoothctl", "disconnect", mac]
            onRunningChanged: { if (!running && mac !== "") btRefresh() }
        }

        Process { id: btRemoveProc; property string mac: ""
            command: ["bluetoothctl", "remove", mac]
            onRunningChanged: { if (!running && mac !== "") btRefresh() }
        }
    }
}
