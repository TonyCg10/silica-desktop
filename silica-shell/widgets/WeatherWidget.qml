import QtQuick
import Quickshell.Io
import "../menus" as Menus

Item {
    id: root
    property real temperature: 0
    property int condition: -1
    property bool loading: true
    property string coordinates: ""
    property bool locationSet: false
    property string locationName: ""
    property var panelWindow
    property rect screenGeometry
    implicitWidth: locationSet ? (loading ? 30 : tempText.implicitWidth + iconText.implicitWidth + 8) : 20
    implicitHeight: 20

    property var weatherPicker: Menus.WeatherPicker {
        panelWindow: root.panelWindow
        screenGeometry: root.screenGeometry
        onLocationSetChanged: {
            if (locationSet) {
                root.locationSet = true
                root.locationName = locationName
                root.coordinates = coordinates
                root.refresh()
            }
        }
    }

    function weatherIcon(code) {
        if (code === 0) return "󰖨"
        if (code <= 3) return "󰖐"
        if (code <= 49) return "󰖑"
        if (code <= 59) return "󰖗"
        if (code <= 69) return "󰖖"
        if (code <= 77) return "󰖏"
        if (code <= 82) return "󰖗"
        if (code <= 86) return "󰖏"
        if (code <= 99) return "󰖓"
        return "󰖐"
    }

    function refresh() {
        if (locationSet && coordinates.length > 0) {
            weatherProc.command = ["curl", "-s", "https://api.open-meteo.com/v1/forecast?" + coordinates + "&current=temperature_2m,weather_code"]
            weatherProc.running = true
        }
    }

    // Setup button (no location)
    Text {
        id: setupIcon
        visible: !root.locationSet
        anchors.centerIn: parent
        text: "󰅟"
        color: "#7aa2f7"
        font.pixelSize: 15
    }

    // Weather display
    Text {
        id: tempText
        visible: root.locationSet && !root.loading
        anchors.left: parent.left
        text: Math.round(root.temperature) + "°"
        color: "#c0caf5"
        font.pixelSize: 13
        font.bold: true
    }

    Text {
        id: iconText
        visible: root.locationSet && !root.loading
        anchors.left: tempText.visible ? tempText.right : parent.left
        anchors.leftMargin: tempText.visible ? 4 : 0
        text: weatherIcon(root.condition)
        color: "#7aa2f7"
        font.pixelSize: 15
    }

    Text {
        id: loadingLabel
        visible: root.locationSet && root.loading
        anchors.centerIn: parent
        text: "..."
        color: "#787c99"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: weatherPicker.visible = true
    }

    Timer {
        interval: 1800000
        running: root.locationSet
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: weatherPicker.loadConfig()

    property var weatherProc: Process {
        id: weatherProc
        property string output: ""
        stdout: SplitParser {
            onRead: (line) => weatherProc.output += line
        }
        onRunningChanged: {
            if (!running && output.length > 0) {
                try {
                    let d = JSON.parse(output)
                    root.temperature = d.current.temperature_2m
                    root.condition = d.current.weather_code
                    root.loading = false
                } catch(e) {}
                output = ""
            }
        }
    }
}
