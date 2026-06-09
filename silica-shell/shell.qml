import QtQuick
import Quickshell
import Quickshell.Io
import "./components"
import "./zones"

ShellRoot {
    id: root

    property string horaSistema: "--:--:--"
    property string fechaSistema: "-- --"
    property int porcentajeBateria: 0
    property var workspaces: ({})
    property string ventanaTitulo: ""
    property string ventanaClase: ""
    property string ventanaIcono: ""
    property var redes: []
    property var brillo: []
    property var audioSalidas: []
    property var audioEntradas: []
    property real volumenActual: 0.75
    property bool volumenMute: false

    Socket {
        id: silicaEngineSocket
        path: "/tmp/silica.sock"
        connected: true

        parser: SplitParser {
            onRead: (line) => {
                try {
                    let datos = JSON.parse(line);
                    root.horaSistema       = datos.hora    ?? root.horaSistema;
                    root.porcentajeBateria = datos.bateria ?? root.porcentajeBateria;
                    root.fechaSistema      = Qt.formatDateTime(new Date(), "ddd d 'de' MMM");
                    if (datos.workspaces)      root.workspaces    = datos.workspaces;
                    if (datos.ventana_titulo !== undefined) root.ventanaTitulo = datos.ventana_titulo;
                    if (datos.ventana_clase  !== undefined) root.ventanaClase  = datos.ventana_clase;
                    if (datos.ventana_icono  !== undefined) root.ventanaIcono  = datos.ventana_icono;
                    if (datos.redes)         root.redes         = datos.redes;
                    if (datos.brillo)        root.brillo        = datos.brillo;
                    if (datos.audio_salidas) root.audioSalidas  = datos.audio_salidas;
                    if (datos.audio_entradas)root.audioEntradas = datos.audio_entradas;
                    if (datos.volumen_actual !== undefined) root.volumenActual = datos.volumen_actual;
                    if (datos.volumen_mute   !== undefined) root.volumenMute   = datos.volumen_mute;
                } catch(e) { console.log("Error parseando JSON:", e); }
            }
        }
        onError: (error) => { connected = false; reconnectTimer.start(); }
        onConnectedChanged: { if (!connected) reconnectTimer.start(); }
    }

    Timer { id: reconnectTimer; interval: 1000; onTriggered: silicaEngineSocket.connected = true }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: panelWin
                required property ShellScreen modelData
                screen: modelData

                readonly property int monitorWorkspace: root.workspaces[modelData.name] || 1

                anchors.top: true; anchors.left: true; anchors.right: true
                implicitHeight: 50
                exclusionMode: ExclusionMode.Auto
                color: "transparent"

                WorkspaceBar {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    activeWorkspace: monitorWorkspace
                }

                DynamicIsland {
                    anchors.centerIn: parent
                    hora: root.horaSistema
                    fecha: root.fechaSistema
                    ventanaTitulo: root.ventanaTitulo
                    ventanaClase: root.ventanaClase
                    ventanaIcono: root.ventanaIcono
                    panelWindow: panelWin
                    screenGeometry: Qt.rect(modelData.x, modelData.y, modelData.width, modelData.height)
                }

                StatusBar {
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    porcentajeBateria: root.porcentajeBateria
                    modelRedes: root.redes
                    modelBrillo: root.brillo
                    modelAudioSalidas: root.audioSalidas
                    modelAudioEntradas: root.audioEntradas
                    volumenActual: root.volumenActual
                    volumenMute: root.volumenMute
                    screenGeometry: Qt.rect(modelData.x, modelData.y, modelData.width, modelData.height)
                    panelWindow: panelWin
                }
            }
        }
    }
}
