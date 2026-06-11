import QtQuick
import "../widgets" as Widgets

Rectangle {
    required property string hora
    required property string fecha
    required property string fechaLarga
    required property string ventanaTitulo
    required property string ventanaClase
    property string ventanaIcono: ""
    required property var panelWindow
    required property rect screenGeometry

    id: islandBar

    // Detectamos el hover sin bloquear los eventos de clic internos
    HoverHandler {
        id: islandHoverHandler
    }
    readonly property bool isHovered: islandHoverHandler.hovered

    // El ancho máximo se expande al hacer hover para dar más espacio
    readonly property int maxWidth: isHovered ? 850 : 600
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
    // Cambia la altura dinámicamente si se hace hover
    height: isHovered ? 68 : 38
    radius: isHovered ? 20 : height / 2
    color: "#16161eDD"
    border.color: "#2f334d"
    border.width: 1
    clip: true

    // Transición suave para el ancho, alto y esquinas rounded
    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
    Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

    Widgets.WindowInfoWidget {
        id: windowInfo
        anchors.verticalCenter: parent.verticalCenter
        // Desplazamos la info de la ventana un poco hacia abajo si está expandido
        anchors.verticalCenterOffset: islandBar.isHovered ? 14 : 0
        x: islandBar.hayVentana ? leftPad : -width
        windowTitle: islandBar.ventanaTitulo
        windowClass: islandBar.ventanaClase
        windowIcon: islandBar.ventanaIcono
        isWindowVisible: islandBar.hayVentana
        expanded: islandBar.isHovered // Pasamos el estado de expansión

        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
    }

    Row {
        id: clockRow
        anchors.verticalCenter: parent.verticalCenter
        // Movemos el reloj y clima hacia arriba al hacer hover
        anchors.verticalCenterOffset: islandBar.isHovered ? -14 : 0
        x: islandBar.width - (width * scale) - rightPad
        spacing: 10

        // Escalado visual para aumentar el tamaño de todo el grupo de forma fluida
        scale: islandBar.isHovered ? 1.15 : 1.0
        transformOrigin: Item.Right

        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

        Widgets.WeatherWidget {
            id: weatherWidget
            panelWindow: islandBar.panelWindow
            screenGeometry: islandBar.screenGeometry
            expanded: islandBar.isHovered
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
            dateLong: islandBar.fechaLarga
            expanded: islandBar.isHovered
        }
    }
}