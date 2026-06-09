import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell._Window

Item {
    id: root
    required property var panelWindow
    required property rect screenGeometry
    property bool menuOpen: false
    property int porcentajeBateria: 0
    signal closeRequested()
    signal popupHoverChanged(bool hovered)

    PopupWindow {
        id: bateriaMenu
        anchor.window: panelWindow
        implicitWidth: 280
        implicitHeight: 120
        visible: root.menuOpen
        color: "transparent"
        anchor.rect.x: screenGeometry.width - width - 24
        anchor.rect.y: 54

        HoverHandler { onHoveredChanged: root.popupHoverChanged(hovered) }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "#1f2335"
            border.color: "#2f334d"; border.width: 1
            focus: true
            Keys.onEscapePressed: root.closeRequested()

            Column {
                anchors.fill: parent; anchors.margins: 12; spacing: 8

                Row { spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        text: porcentajeBateria >= 80 ? "\uF0E4D" : porcentajeBateria >= 50 ? "\uF0E4C" : porcentajeBateria >= 20 ? "\uF0E4A" : "\uF0E48"
                        color: porcentajeBateria <= 15 ? "#f7768e" : "#9ece6a"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { text: "Bater\u00EDa"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: porcentajeBateria + "%"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }

                Rectangle { width: parent.width; height: 8; radius: 4; color: "#2f334d"
                    Rectangle { width: parent.width * (porcentajeBateria / 100); height: parent.height; radius: 4; color: porcentajeBateria <= 15 ? "#f7768e" : "#9ece6a" }
                }

                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: porcentajeBateria <= 15 ? "Conecta el cargador" : porcentajeBateria <= 30 ? "Bater\u00EDa baja" : "Carga OK"
                    color: porcentajeBateria <= 15 ? "#f7768e" : "#787c99"; font.pixelSize: 11
                }
            }
        }
    }
}
