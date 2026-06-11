import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell._Window
import "../components" as Components

Item {
    id: root
    implicitHeight: menuContainer.childrenRect.height
    required property var panelWindow
    required property rect screenGeometry
    property bool menuOpen: false
    property int porcentajeBateria: 0
    signal closeRequested()
    signal popupHoverChanged(bool hovered)

    Item {
        id: menuContainer
        width: parent.width
        implicitHeight: contentColumn.childrenRect.height
        opacity: root.menuOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: opacity > 0
        
        Rectangle {
            width: parent.width
            implicitHeight: contentColumn.childrenRect.height
            radius: 12
            color: "#1f2335"
            border.color: "#2f334d"; border.width: 1
            focus: true
            Keys.onEscapePressed: root.closeRequested()

            Column {
                id: contentColumn
                anchors.margins: 12; spacing: 8

                    Components.SectionHeader {
                        icon: porcentajeBateria >= 80 ? Components.IconSystem.battery.full : (porcentajeBateria >= 50 ? Components.IconSystem.battery.high : (porcentajeBateria >= 20 ? Components.IconSystem.battery.medium : (porcentajeBateria >= 5 ? Components.IconSystem.battery.low : Components.IconSystem.battery.critical)))
                        iconColor: "#ffffff"
                        title: "Batería"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: porcentajeBateria + "%"
                            color: "#c0caf5"
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                Rectangle { width: parent.width; height: 8; radius: 4; color: "#2f334d"
                    Rectangle { width: parent.width * (porcentajeBateria / 100); height: parent.height; radius: 4; color: porcentajeBateria <= 15 ? "#f7768e" : "#9ece6a" }
                }

                Text {
                    height: contentHeight; horizontalAlignment: Text.AlignHCenter
                    text: porcentajeBateria <= 15 ? "Conecta el cargador" : porcentajeBateria <= 30 ? "Bater\u00EDa baja" : "Carga OK"
                    color: porcentajeBateria <= 15 ? "#f7768e" : "#787c99"; font.pixelSize: 11
                }
            }
        }
    }
}
