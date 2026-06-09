import QtQuick
import "../widgets" as Widgets

Rectangle {
    required property string hora
    required property string fecha
    required property string ventanaTitulo
    required property string ventanaClase
    property string ventanaIcono: ""
    required property var panelWindow
    required property rect screenGeometry

    id: islandBar

    readonly property int maxWidth: 600
    readonly property bool hayVentana: ventanaTitulo.length > 0 || ventanaClase.length > 0

    readonly property int leftPad: 24
    readonly property int rightPad: 16

    readonly property int minWidth: clockRow.implicitWidth + weatherWidget.width + rightPad * 2

    readonly property int idealWidth: {
        if (!hayVentana) return minWidth
        let iconoW = Math.max(18, windowInfo.iconWidth)
        let tituloMax = maxWidth - leftPad - rightPad - iconoW - windowInfo.spacing
        let tituloAncho = Math.min(windowInfo.tituloImplicitWidth, tituloMax)
        return leftPad + iconoW + windowInfo.spacing + tituloAncho + rightPad + clockRow.implicitWidth + weatherWidget.width + 8
    }

    width: Math.min(maxWidth, idealWidth)
    height: 38
    radius: height / 2
    color: "#16161eDD"
    border.color: "#2f334d"
    border.width: 1
    clip: true

    Behavior on width {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }

    Widgets.WindowInfoWidget {
        id: windowInfo
        anchors.verticalCenter: parent.verticalCenter
        x: islandBar.hayVentana ? leftPad : -width
        windowTitle: islandBar.ventanaTitulo
        windowClass: islandBar.ventanaClase
        windowIcon: islandBar.ventanaIcono
        isWindowVisible: islandBar.hayVentana

        Behavior on x {
            NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
        }
    }

    Row {
        id: clockRow
        anchors.verticalCenter: parent.verticalCenter
        x: islandBar.width - width - rightPad
        spacing: 10

        Widgets.WeatherWidget {
            id: weatherWidget
            panelWindow: islandBar.panelWindow
            screenGeometry: islandBar.screenGeometry
        }

        Rectangle {
            width: 1; height: 14
            color: "#414868"
            anchors.verticalCenter: parent.verticalCenter
        }

        Widgets.ClockWidget {
            time: islandBar.hora
        }

        Rectangle {
            width: 1; height: 14
            color: "#414868"
            anchors.verticalCenter: parent.verticalCenter
        }

        Widgets.DateWidget {
            date: islandBar.fecha
        }
    }
}
