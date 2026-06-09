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
    property var modelBrillo

    ListModel { id: brilloModel }

    function sincronizarBrillo() {
        var src = modelBrillo
        if (!src || src.length === 0) return
        var i = 0
        while (i < src.length && i < brilloModel.count) {
            brilloModel.setProperty(i, "nombre", src[i].nombre)
            brilloModel.setProperty(i, "actual", src[i].actual)
            brilloModel.setProperty(i, "maximo", src[i].maximo)
            brilloModel.setProperty(i, "display_num", src[i].display_num)
            i++
        }
        while (i < src.length) {
            brilloModel.append({ nombre: src[i].nombre, actual: src[i].actual, maximo: src[i].maximo, display_num: src[i].display_num })
            i++
        }
    }

    onModelBrilloChanged: sincronizarBrillo()
    onMenuOpenChanged: { if (menuOpen) sincronizarBrillo() }

    PopupWindow {
        id: brilloMenu
        anchor.window: panelWindow
        implicitWidth: 300
        implicitHeight: 50 + brilloModel.count * 34 + 12
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
            clip: true
            focus: true
            Keys.onEscapePressed: root.closeRequested()

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                Row {
                    spacing: 6; anchors.horizontalCenter: parent.horizontalCenter
                    Text { text: "\uF0CFF"; color: "#7aa2f7"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Brillo"; color: "#c0caf5"; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }

                Repeater {
                    model: brilloModel
                    delegate: Rectangle {
                        id: brilloItem
                        width: 288; height: 28; radius: 6
                        color: "transparent"
                        property real valor: model.actual / Math.max(model.maximo, 1)

                        Process {
                            id: cmdSetBrillo
                            command: ["ddcutil", "setvcp", "10", Math.round(brilloItem.valor * 100).toString(), "--display", model.display_num.toString()]
                        }

                        Row {
                            anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4; spacing: 6
                            Text {
                                text: model.nombre.indexOf("DP-") === 0 ? "\uF10F0" : model.nombre.indexOf("HDMI-") === 0 ? "\uF1387" : "\uF0CFF"
                                color: "#c0caf5"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                            }
                            Item {
                                id: sliderItem; width: parent.width - 70; height: 16; anchors.verticalCenter: parent.verticalCenter
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: "#2f334d"
                                    Rectangle { width: parent.width * brilloItem.valor; height: 4; radius: 2; color: "#e0af68" }
                                }
                                Rectangle { x: (sliderItem.width - 10) * brilloItem.valor; anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 5; color: "#c0caf5"; border.color: "#2f334d"; border.width: 1 }
                                MouseArea {
                                    anchors.fill: parent; acceptedButtons: Qt.LeftButton
                                    onPositionChanged: (mouse) => { if (mouse.buttons & Qt.LeftButton) { brilloItem.valor = Math.max(0, Math.min(1, mouse.x / sliderItem.width)); cmdSetBrillo.running = true } }
                                    onClicked: (mouse) => { brilloItem.valor = Math.max(0, Math.min(1, mouse.x / sliderItem.width)); cmdSetBrillo.running = true }
                                    onWheel: (wheel) => { var pct = brilloItem.valor * 100; pct = wheel.angleDelta.y > 0 ? Math.ceil(Math.min(pct, 99) / 5 + 1) * 5 : Math.floor(Math.max(pct, 1) / 5 - 1) * 5; brilloItem.valor = Math.max(0, Math.min(100, pct)) / 100; cmdSetBrillo.running = true }
                                }
                            }
                            Text { text: Math.round(brilloItem.valor * 100) + "%"; color: "#787c99"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter; width: 30; horizontalAlignment: Text.AlignRight }
                        }
                    }
                }

                Item { visible: brilloModel.count === 0; width: parent.width; height: 24
                    Text { text: "No hay controles de brillo"; color: "#565f89"; font.pixelSize: 10; anchors.centerIn: parent }
                }
            }
        }
    }
}
