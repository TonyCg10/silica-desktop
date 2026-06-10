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
            clip: true
            focus: true
            Keys.onEscapePressed: root.closeRequested()

            Column {
                id: contentColumn
                width: parent.width
                anchors.margins: 6
                spacing: 4

                    // ── BRIGHTNESS section header ──
                    Item { width: 1; implicitHeight: 6 }
                    Components.SectionHeader {
                        icon: "\uF0CFF"
                        title: "Brillo"
                        iconColor: "#e0af68"
                    }
                    Item { width: 1; implicitHeight: 6 }

                Repeater {
                    model: brilloModel
                    delegate: Rectangle {
                        id: brilloItem
                        width: parent ? parent.width : 276; height: 28; implicitHeight: 28; radius: 6
                        color: "transparent"
                        property real valor: model.actual / Math.max(model.maximo, 1)
                        property bool dragging: false
                        property real dragValor: 0.0
                        property real displayValor: dragging ? dragValor : valor

                        Timer {
                            id: setBrilloTimer
                            interval: 100
                            repeat: false
                            property real pendingVal: 0.0
                            onTriggered: {
                                brilloItem.valor = pendingVal
                                cmdSetBrillo.running = true
                            }
                        }

                        Process {
                            id: cmdSetBrillo
                            command: ["ddcutil", "setvcp", "10", Math.round(brilloItem.valor * 100).toString(), "--display", model.display_num.toString()]
                        }

                            Row {
                                anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4; spacing: 6
                                Components.SpinnerIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spinning: cmdSetBrillo.running
                                    icon: model.nombre.indexOf("DP-") === 0 ? "\uF10F0" : model.nombre.indexOf("HDMI-") === 0 ? "\uF1387" : "\uF0CFF"
                                    activeColor: "#e0af68"
                                    idleColor: "#c0caf5"
                                    size: 11
                                }
                            Components.SliderWidget {
                                id: sliderItem
                                width: parent.width - 70; height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                value: brilloItem.displayValor
                                accentColor: "#e0af68"
                                onMoved: (newValue) => {
                                    brilloItem.dragValor = newValue
                                    setBrilloTimer.pendingVal = newValue
                                    setBrilloTimer.restart()
                                }
                                onPressedChanged: {
                                    brilloItem.dragging = pressed
                                    if (pressed) {
                                        brilloItem.dragValor = brilloItem.valor
                                    }
                                }
                            }
                            Text { text: Math.round(brilloItem.displayValor * 100) + "%"; color: "#787c99"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter; width: 30; horizontalAlignment: Text.AlignRight }
                        }
                    }
                }

                Item { visible: brilloModel.count === 0; width: parent.width; height: 24; implicitHeight: brilloModel.count === 0 ? 24 : 0
                    Text { text: "No hay controles de brillo"; color: "#565f89"; font.pixelSize: 10; anchors.centerIn: parent }
                }
            }
        }
    }
}
