import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell._Window
import "../components" as Components

Item {
    id: root
    required property var panelWindow
    required property rect screenGeometry
    property bool menuOpen: false
    signal closeRequested()
    signal popupHoverChanged(bool hovered)
    property var modelSalidas
    property var modelEntradas
    property real volumenActual
    property bool volumenMute

    implicitHeight: menuContainer.implicitHeight

    ListModel { id: audioSalidasModel }
    ListModel { id: audioEntradasModel }

    function syncAudioModel(dst, src) {
        if (!src || src.length === 0) return
        var i = 0
        while (i < src.length && i < dst.count) {
            dst.setProperty(i, "nombre", src[i].nombre)
            dst.setProperty(i, "descripcion", src[i].descripcion)
            dst.setProperty(i, "volumen", src[i].volumen)
            dst.setProperty(i, "mute", src[i].mute)
            dst.setProperty(i, "predeterminado", src[i].predeterminado)
            dst.setProperty(i, "node_id", src[i].node_id)
            i++
        }
        while (i < src.length) {
            dst.append({
                nombre: src[i].nombre,
                descripcion: src[i].descripcion,
                volumen: src[i].volumen,
                mute: src[i].mute,
                predeterminado: src[i].predeterminado,
                node_id: src[i].node_id
            })
            i++
        }
    }

    onModelSalidasChanged: syncAudioModel(audioSalidasModel, modelSalidas)
    onModelEntradasChanged: syncAudioModel(audioEntradasModel, modelEntradas)
    onMenuOpenChanged: {
        if (menuOpen) {
            syncAudioModel(audioSalidasModel, modelSalidas)
            syncAudioModel(audioEntradasModel, modelEntradas)
        }
    }

    Item {
        id: menuContainer
        width: parent.width
        implicitHeight: audioListColumn.implicitHeight
        opacity: root.menuOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: opacity > 0

        Rectangle {
            width: parent.width
            height: parent.implicitHeight
            implicitHeight: parent.implicitHeight
            radius: 14
            color: "transparent"
            clip: true
            focus: true
            Keys.onEscapePressed: root.closeRequested()

            Flickable {
                width: parent.width
                height: contentHeight
                contentHeight: audioListColumn.implicitHeight
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: audioListColumn
                    width: parent.width
                    spacing: 0

                    // ── SALIDAS section header ──
                    Item { width: 1; implicitHeight: 12 }
                    Components.SectionHeader {
                        anchors.leftMargin: 12
                        icon: volumenMute ? "\uF0D59" : "\uF0D5A"
                        title: "SALIDAS"
                    }
                    Item { width: 1; implicitHeight: 4 }

                    // ── Salidas devices ──
                    Repeater {
                        model: audioSalidasModel
                        delegate: Item {
                            id: salidaItem
                            width: audioListColumn.width
                            implicitHeight: salidaInnerCol.implicitHeight + 10

                            property real vol: model.volumen
                            property bool devMuted: model.mute
                            property bool dragging: false
                            property real dragVol: 0.0
                            property real displayVol: dragging ? dragVol : vol

                            Timer {
                                id: salidaVolTimer; interval: 50; repeat: false
                                property real pendingVol: 0.0
                                onTriggered: Quickshell.execDetached(["wpctl", "set-volume", model.node_id.toString(), pendingVol.toFixed(2)])
                            }

                            Column {
                                id: salidaInnerCol
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.right: parent.right; anchors.rightMargin: 10
                                anchors.top: parent.top; anchors.topMargin: 5
                                spacing: 5

                                Row {
                                    width: parent.width; spacing: 4
                                    Text {
                                        text: model.predeterminado ? "\uF03ED" : ""
                                        color: "#7aa2f7"; font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        width: parent.width - 36
                                        text: model.descripcion || model.nombre
                                        color: model.predeterminado ? "#c0caf5" : "#787c99"
                                        font.pixelSize: 11; font.bold: model.predeterminado
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: salidaMuteArea.containsMouse ? "#2f334d" : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: salidaItem.devMuted ? "\uF075A" : "\uF06A0"
                                            color: salidaItem.devMuted ? "#f7768e" : "#7aa2f7"
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: salidaMuteArea; anchors.fill: parent; hoverEnabled: true
                                            onClicked: {
                                                let cmd = salidaItem.devMuted
                                                    ? "wpctl set-mute " + model.node_id + " toggle"
                                                    : "wpctl set-mute " + model.node_id + " 1"
                                                Quickshell.execDetached(cmd.split(" "))
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width; spacing: 6
                                    Components.SliderWidget {
                                        id: salidaSlider
                                        width: parent.width - 42; height: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        value: salidaItem.displayVol
                                        accentColor: salidaItem.devMuted ? "#565f89" : "#7aa2f7"
                                        onMoved: (newValue) => {
                                            salidaItem.dragVol = newValue
                                            salidaVolTimer.pendingVol = newValue
                                            salidaVolTimer.restart()
                                        }
                                        onPressedChanged: {
                                            salidaItem.dragging = pressed
                                            if (pressed) {
                                                salidaItem.dragVol = salidaItem.vol
                                            }
                                        }
                                    }
                                    Text {
                                        text: Math.round(salidaItem.displayVol * 100) + "%"
                                        color: "#787c99"; font.pixelSize: 10
                                        width: 36; horizontalAlignment: Text.AlignRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        visible: audioSalidasModel.count === 0
                        width: parent.width; implicitHeight: audioSalidasModel.count === 0 ? 28 : 0
                        Text { text: "Sin dispositivos de salida"; color: "#3b4261"; font.pixelSize: 10; anchors.centerIn: parent }
                    }

                    // ── Divider ──
                    Item { width: 1; implicitHeight: 8 }
                    Components.Separator { margins: 12 }
                    Item { width: 1; implicitHeight: 8 }

                    // ── ENTRADAS section header ──
                    Components.SectionHeader {
                        anchors.leftMargin: 12
                        icon: "\uF03E5"
                        title: "ENTRADAS"
                    }
                    Item { width: 1; implicitHeight: 4 }

                    // ── Entradas devices ──
                    Repeater {
                        model: audioEntradasModel
                        delegate: Item {
                            id: entradaItem
                            width: audioListColumn.width
                            implicitHeight: entradaInnerCol.implicitHeight + 10

                            property real vol: model.volumen
                            property bool devMuted: model.mute
                            property bool dragging: false
                            property real dragVol: 0.0
                            property real displayVol: dragging ? dragVol : vol

                            Timer {
                                id: entradaVolTimer; interval: 50; repeat: false
                                property real pendingVol: 0.0
                                onTriggered: Quickshell.execDetached(["wpctl", "set-volume", model.node_id.toString(), pendingVol.toFixed(2)])
                            }

                            Column {
                                id: entradaInnerCol
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.right: parent.right; anchors.rightMargin: 10
                                anchors.top: parent.top; anchors.topMargin: 5
                                spacing: 5

                                Row {
                                    width: parent.width; spacing: 4
                                    Text {
                                        text: model.predeterminado ? "\uF03ED" : ""
                                        color: "#7aa2f7"; font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        width: parent.width - 36
                                        text: model.descripcion || model.nombre
                                        color: model.predeterminado ? "#c0caf5" : "#787c99"
                                        font.pixelSize: 11; font.bold: model.predeterminado
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: entradaMuteArea.containsMouse ? "#2f334d" : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: entradaItem.devMuted ? "\uF075A" : "\uF06A0"
                                            color: entradaItem.devMuted ? "#f7768e" : "#7aa2f7"
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: entradaMuteArea; anchors.fill: parent; hoverEnabled: true
                                            onClicked: {
                                                let cmd = entradaItem.devMuted
                                                    ? "wpctl set-mute " + model.node_id + " toggle"
                                                    : "wpctl set-mute " + model.node_id + " 1"
                                                Quickshell.execDetached(cmd.split(" "))
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width; spacing: 6
                                    Components.SliderWidget {
                                        id: entradaSlider
                                        width: parent.width - 42; height: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        value: entradaItem.displayVol
                                        accentColor: entradaItem.devMuted ? "#565f89" : "#7aa2f7"
                                        onMoved: (newValue) => {
                                            entradaItem.dragVol = newValue
                                            entradaVolTimer.pendingVol = newValue
                                            entradaVolTimer.restart()
                                        }
                                        onPressedChanged: {
                                            entradaItem.dragging = pressed
                                            if (pressed) {
                                                entradaItem.dragVol = entradaItem.vol
                                            }
                                        }
                                    }
                                    Text {
                                        text: Math.round(entradaItem.displayVol * 100) + "%"
                                        color: "#787c99"; font.pixelSize: 10
                                        width: 36; horizontalAlignment: Text.AlignRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        visible: audioEntradasModel.count === 0
                        width: parent.width; implicitHeight: audioEntradasModel.count === 0 ? 28 : 0
                        Text { text: "Sin dispositivos de entrada"; color: "#3b4261"; font.pixelSize: 10; anchors.centerIn: parent }
                    }

                    // ── Default device button ──
                    Item { width: 1; implicitHeight: 8 }
                    Rectangle {
                        width: parent.width - 24; implicitHeight: 28; height: 28; radius: 6; x: 12
                        color: defBtn.containsMouse ? "#24283b" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "Dispositivo predeterminado..."
                            color: "#565f89"; font.pixelSize: 10
                        }
                        MouseArea {
                            id: defBtn; anchors.fill: parent; hoverEnabled: true
                            onClicked: Quickshell.execDetached(["wpctl", "set-default", "@DEFAULT_SINK@"])
                        }
                    }
                    Item { width: 1; implicitHeight: 10 }
                }
            }
        }
    }
}
