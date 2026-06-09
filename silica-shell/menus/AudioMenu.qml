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
    property var modelSalidas
    property var modelEntradas
    property real volumenActual
    property bool volumenMute

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

    PopupWindow {
        id: audioMenu
        anchor.window: panelWindow
        implicitWidth: 360
        implicitHeight: Math.max(audioSalidasModel.count, audioEntradasModel.count, 1) * 60 + 66
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

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Column {
                    width: (parent.width - 8) / 2; spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text { text: (volumenMute ? "\uF0D59" : "\uF0D5A") + "  SALIDAS"; color: "#565f89"; font.pixelSize: 9; leftPadding: 2 }

                    Repeater {
                        model: audioSalidasModel
                        delegate: Item {
                            width: parent.width; height: 52
                            property real vol: model.volumen
                            property bool devMuted: model.mute

                            Column {
                                anchors.left: parent.left; anchors.leftMargin: 2
                                anchors.right: parent.right; anchors.rightMargin: 2
                                spacing: 2

                                Row {
                                    width: parent.width; spacing: 4
                                    Text {
                                        text: model.predeterminado ? "\uF03ED" : ""
                                        color: "#7aa2f7"; font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        width: parent.width - 30
                                        text: model.descripcion || model.nombre
                                        color: model.predeterminado ? "#c0caf5" : "#787c99"
                                        font.pixelSize: 10; font.bold: model.predeterminado
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: muteArea.containsMouse ? "#2f334d" : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: devMuted ? "\uF075A" : "\uF06A0"
                                            color: devMuted ? "#f7768e" : "#7aa2f7"
                                            font.pixelSize: 10
                                        }
                                        MouseArea {
                                            id: muteArea; anchors.fill: parent; hoverEnabled: true
                                            onClicked: {
                                                let cmd = devMuted ? "wpctl set-mute " + model.node_id + " toggle" : "wpctl set-mute " + model.node_id + " 1"
                                                Quickshell.execDetached(cmd.split(" "))
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width; spacing: 4
                                    Item { width: 16; height: 1 }

                                    Rectangle {
                                        width: parent.width - 22; height: 14; radius: 7
                                        color: "#24283b"
                                        Rectangle {
                                            width: Math.max(0, Math.min(1, vol)) * parent.width
                                            height: parent.height; radius: 7
                                            color: "#7aa2f7"
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: (mouse) => {
                                                let newVol = Math.max(0, Math.min(1, mouse.x / width))
                                                Quickshell.execDetached(["wpctl", "set-volume", model.node_id.toString(), newVol.toFixed(2)])
                                            }
                                        }
                                        property real dragStartVol: 0
                                        property real dragStartX: 0
                                        MouseArea {
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onWheel: (wheel) => {
                                                let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                                                let newVol = Math.max(0, Math.min(1, vol + delta))
                                                Quickshell.execDetached(["wpctl", "set-volume", model.node_id.toString(), newVol.toFixed(2)])
                                            }
                                            onPressed: (mouse) => { dragStartVol = vol; dragStartX = mouse.x; dragStartX = mapToItem(null, mouse.x, 0).x }
                                            onPositionChanged: (mouse) => {
                                                if (!pressed) return
                                                let globalX = mapToItem(null, mouse.x, 0).x
                                                let delta = (globalX - dragStartX) / 200
                                                let newVol = Math.max(0, Math.min(1, dragStartVol + delta))
                                                Quickshell.execDetached(["wpctl", "set-volume", model.node_id.toString(), newVol.toFixed(2)])
                                            }
                                        }
                                    }

                                    Text {
                                        text: Math.round(vol * 100) + "%"
                                        color: "#565f89"; font.pixelSize: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    Item { visible: audioSalidasModel.count === 0; width: parent.width; height: 12
                        Text { text: "Sin dispositivos"; color: "#3b4261"; font.pixelSize: 8; anchors.centerIn: parent }
                    }
                }

                Rectangle { width: 1; height: parent.height - 16; anchors.verticalCenter: parent.verticalCenter; color: "#2f334d" }

                Column {
                    width: (parent.width - 8) / 2; spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text { text: "\uF03E5  ENTRADAS"; color: "#565f89"; font.pixelSize: 9; leftPadding: 2 }

                    Repeater {
                        model: audioEntradasModel
                        delegate: Item {
                            width: parent.width; height: 52
                            property real vol: model.volumen
                            property bool devMuted: model.mute

                            Column {
                                anchors.left: parent.left; anchors.leftMargin: 2
                                anchors.right: parent.right; anchors.rightMargin: 2
                                spacing: 2

                                Row {
                                    width: parent.width; spacing: 4
                                    Text {
                                        text: model.predeterminado ? "\uF03ED" : ""
                                        color: "#7aa2f7"; font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        width: parent.width - 30
                                        text: model.descripcion || model.nombre
                                        color: model.predeterminado ? "#c0caf5" : "#787c99"
                                        font.pixelSize: 10; font.bold: model.predeterminado
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: muteAreaIn.containsMouse ? "#2f334d" : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: devMuted ? "\uF075A" : "\uF06A0"
                                            color: devMuted ? "#f7768e" : "#7aa2f7"
                                            font.pixelSize: 10
                                        }
                                        MouseArea {
                                            id: muteAreaIn; anchors.fill: parent; hoverEnabled: true
                                            onClicked: {
                                                let cmd = devMuted ? "wpctl set-mute " + model.node_id + " toggle" : "wpctl set-mute " + model.node_id + " 1"
                                                Quickshell.execDetached(cmd.split(" "))
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width; spacing: 4
                                    Item { width: 16; height: 1 }

                                    Rectangle {
                                        width: parent.width - 22; height: 14; radius: 7
                                        color: "#24283b"
                                        Rectangle {
                                            width: Math.max(0, Math.min(1, vol)) * parent.width
                                            height: parent.height; radius: 7
                                            color: "#7aa2f7"
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: (mouse) => {
                                                let newVol = Math.max(0, Math.min(1, mouse.x / width))
                                                Quickshell.execDetached(["wpctl", "set-volume", model.node_id.toString(), newVol.toFixed(2)])
                                            }
                                        }
                                    }

                                    Text {
                                        text: Math.round(vol * 100) + "%"
                                        color: "#565f89"; font.pixelSize: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    Item { visible: audioEntradasModel.count === 0; width: parent.width; height: 12
                        Text { text: "Sin dispositivos"; color: "#3b4261"; font.pixelSize: 8; anchors.centerIn: parent }
                    }

                    Rectangle {
                        width: parent.width - 8; height: 24; radius: 6
                        color: defBtn.containsMouse ? "#24283b" : "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "Dispositivo predeterminado..."; color: "#565f89"; font.pixelSize: 8 }
                        MouseArea { id: defBtn; anchors.fill: parent; hoverEnabled: true
                            onClicked: Quickshell.execDetached(["wpctl", "set-default", "@DEFAULT_SINK@"])
                        }
                    }
                }
            }
        }
    }
}
