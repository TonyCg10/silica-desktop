import QtQuick
import Quickshell.Io
import "../components" as Components
import "../menus" as Menus

Item {
    id: root
    property real temperature: 0
    property real feelsLike: 0
    property int humidity: 0
    property real windSpeed: 0
    property int rainProbability: 0
    property int condition: -1
    property bool loading: true
    property bool expanded: false
    property string coordinates: ""
    property bool locationSet: false
    property string locationName: ""
    property var panelWindow
    property rect screenGeometry
    implicitWidth: locationSet ? (loading ? 30 : expanded ? expandedRow.implicitWidth + 16 : tempText.implicitWidth + iconText.implicitWidth + 8) : 20
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
        if (code === 0) return Components.IconSystem.weather.clear
        if (code <= 3) return Components.IconSystem.weather.partlyCloudy
        if (code <= 49) return Components.IconSystem.weather.cloudy
        if (code <= 59) return Components.IconSystem.weather.rain
        if (code <= 69) return Components.IconSystem.weather.snow
        if (code <= 77) return Components.IconSystem.weather.snow
        if (code <= 82) return Components.IconSystem.weather.rain
        if (code <= 86) return Components.IconSystem.weather.heavyRain
        if (code <= 99) return Components.IconSystem.weather.tornado
        return Components.IconSystem.weather.cloudy
    }

    function refresh() {
        if (locationSet && coordinates.length > 0) {
            weatherProc.command = ["curl", "-s", "https://api.open-meteo.com/v1/forecast?" + coordinates + "&current=temperature_2m,weather_code,apparent_temperature,relative_humidity_2m,wind_speed_10m,precipitation_probability"]
            weatherProc.running = true
        }
    }

    // Setup button (no location)
    Text {
        id: setupIcon
        visible: !root.locationSet
        anchors.centerIn: parent
        text: Components.IconSystem.action.settings
        color: "#ffffff"
        font.family: Components.IconSystem.fontFamily
        font.pixelSize: 15
    }

    // Weather display
    Text {
        id: iconText 
        visible: root.locationSet && !root.loading && !root.expanded
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter 
        text: weatherIcon(root.condition) 
        color: "#ffffff" 
        font.family: Components.IconSystem.fontFamily 
        font.pixelSize: 12
    }

    Text {
        id: tempText
        visible: root.locationSet && !root.loading && !root.expanded
        anchors.left: iconText.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter 
        text: Math.round(root.temperature) + "°" 
        color: "#ffffff"
        font.pixelSize: 14
        font.bold: true
    }

    Row {
        id: expandedRow
        visible: root.locationSet && !root.loading && root.expanded
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            text: weatherIcon(root.condition)
            color: "#ffffff"
            font.family: Components.IconSystem.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Math.round(root.temperature) + "°"
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle { width: 1; height: 12; color: "#414868"; anchors.verticalCenter: parent.verticalCenter }

        Row {
            spacing: 4
            Text {
                text: Components.IconSystem.weather.thermometer
                color: "#ffffff"
                font.family: Components.IconSystem.fontFamily
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: Math.round(root.feelsLike) + "°"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle { width: 1; height: 12; color: "#414868"; anchors.verticalCenter: parent.verticalCenter }

        Row {
            spacing: 4
            Text {
                text: Components.IconSystem.weather.drop
                color: "#ffffff"
                font.family: Components.IconSystem.fontFamily
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: root.humidity + "%"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle { width: 1; height: 12; color: "#414868"; anchors.verticalCenter: parent.verticalCenter }

        Row {
            spacing: 4
            Text {
                text: Components.IconSystem.weather.wind
                color: "#ffffff"
                font.family: Components.IconSystem.fontFamily
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: Math.round(root.windSpeed) + " km/h"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle { width: 1; height: 12; color: "#414868"; anchors.verticalCenter: parent.verticalCenter }

        Row {
            spacing: 4
            Text {
                text: Components.IconSystem.weather.rain
                color: "#ffffff"
                font.family: Components.IconSystem.fontFamily
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: root.rainProbability + "%"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
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
                    root.feelsLike = d.current.apparent_temperature
                    root.humidity = d.current.relative_humidity_2m
                    root.windSpeed = d.current.wind_speed_10m
                    root.rainProbability = d.current.precipitation_probability
                    root.loading = false
                } catch(e) {}
                output = ""
            }
        }
    }
}
