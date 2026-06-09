import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root
    property string coordinates: ""
    property var panelWindow
    property rect screenGeometry
    property bool locationSet: false
    property string locationName: ""
    property string searchQuery: ""
    property var searchResults: []
    property bool searching: false

    visible: false
    title: "weather-picker"
    implicitWidth: 400
    implicitHeight: 260
    color: "#1a1b26DD"

    onVisibleChanged: {
        if (visible) {
            searchField.forceActiveFocus()
            if (locationSet) searchQuery = locationName
        }
    }

    function loadConfig() {
        Qt.callLater(() => {
            configReader.command = ["cat", "/home/toni/.config/silica/weather.json"]
            configReader.running = true
        })
    }

    function saveConfig(name, lat, lon, tz) {
        let json = JSON.stringify({name, latitude: lat, longitude: lon, timezone: tz})
        saveProc.command = ["bash", "-c", `mkdir -p /home/toni/.config/silica && echo '${json}' > /home/toni/.config/silica/weather.json`]
        saveProc.running = true
        locationName = name
        coordinates = `latitude=${lat}&longitude=${lon}&timezone=${tz}`
        locationSet = true
        root.visible = false
        weatherWidget.refresh()
    }

    property var configReader: Process {
        id: configReader
        property string output: ""
        command: ["cat", "/home/toni/.config/silica/weather.json"]
        stdout: SplitParser {
            onRead: (line) => configReader.output += line
        }
        onRunningChanged: {
            if (!running) {
                if (output.length > 0) {
                    try {
                        let cfg = JSON.parse(output)
                        locationName = cfg.name || ""
                        coordinates = `latitude=${cfg.latitude}&longitude=${cfg.longitude}&timezone=${cfg.timezone || "auto"}`
                        locationSet = locationName.length > 0
                        if (locationSet) weatherWidget.refresh()
                    } catch(e) {}
                }
                output = ""
            }
        }
    }

    property var saveProc: Process {
        id: saveProc
        onRunningChanged: {
            if (!running) {
                root.visible = false
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Text {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 12
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            text: root.locationSet ? "Ubicación actual: " + root.locationName : "Establecer ubicación"
            color: "#c0caf5"
            font.pixelSize: 14
            font.bold: true
        }

        TextField {
            id: searchField
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 36
            placeholderText: "Buscar ciudad..."
            placeholderTextColor: "#414868"
            color: "#c0caf5"
            font.pixelSize: 13
            background: Rectangle {
                radius: 6
                color: "#16161e"
                border.color: searchField.activeFocus ? "#7aa2f7" : "#2f334d"
                border.width: 1
            }
            onTextChanged: {
                root.searchQuery = text
                if (text.length >= 2) searchTimer.restart()
                else root.searchResults = []
            }
            Keys.onReturnPressed: {
                if (root.searchResults.length > 0) {
                    let r = root.searchResults[0]
                    root.saveConfig(r.name, r.latitude, r.longitude, r.timezone || "auto")
                }
            }
        }

        Timer {
            id: searchTimer
            interval: 300
            onTriggered: geocodeProcess.run(root.searchQuery)
        }

        property var geocodeProcess: Process {
            id: geocodeProcess
            property string output: ""
            property string query: ""
            function run(q) {
                query = q
                output = ""
                command = ["curl", "-s", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(q) + "&count=5&language=es"]
                running = true
            }
            stdout: SplitParser {
                onRead: (line) => geocodeProcess.output += line
            }
            onRunningChanged: {
                if (!running && output.length > 0) {
                    try {
                        let d = JSON.parse(output)
                        root.searchResults = d.results || []
                    } catch(e) {
                        root.searchResults = []
                    }
                    output = ""
                }
            }
        }

        Column {
            anchors.top: searchField.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 2

            Repeater {
                model: root.searchResults
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: searchField.width
                    height: 36
                    radius: 6
                    color: resultMouse.containsMouse ? "#2f334d" : "transparent"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        spacing: 8

                        Text {
                            text: modelData.name || ""
                            color: "#c0caf5"
                            font.pixelSize: 13
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: [modelData.admin1, modelData.country].filter(Boolean).join(", ")
                            color: "#787c99"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: resultMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let tz = modelData.timezone || "auto"
                            root.saveConfig(modelData.name, modelData.latitude, modelData.longitude, tz)
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: loadConfig()
}
