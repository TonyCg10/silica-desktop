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
    property var workspacesPorMonitor: ({})
    property var ventanasPorWorkspace: ({})
    property string ventanaTitulo: ""
    property string ventanaClase: ""
    property string ventanaIcono: ""
    property var redes: []
    property var brillo: []
    property var audioSalidas: []
    property var audioEntradas: []
    property real volumenActual: 0.75
    property bool volumenMute: false
    property var bluetoothDevices: []
    property bool btPowerOn: false

    property var todosLosWorkspaces: {
        let arr = [];
        for (let mon in workspacesPorMonitor) {
            let list = workspacesPorMonitor[mon];
            for (let i = 0; i < list.length; i++) {
                if (!arr.includes(list[i])) {
                    arr.push(list[i]);
                }
            }
        }
        return arr.sort(function(a, b){ return a - b });
    }

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

                    if (datos.workspaces) {
                        if (JSON.stringify(datos.workspaces) !== JSON.stringify(root.workspaces)) {
                            root.workspaces = datos.workspaces;
                        }
                    }
                    if (datos.workspaces_por_monitor) {
                        if (JSON.stringify(datos.workspaces_por_monitor) !== JSON.stringify(root.workspacesPorMonitor)) {
                            root.workspacesPorMonitor = datos.workspaces_por_monitor;
                        }
                    }
                    if (datos.ventanas_por_workspace) {
                        if (JSON.stringify(datos.ventanas_por_workspace) !== JSON.stringify(root.ventanasPorWorkspace)) {
                            root.ventanasPorWorkspace = datos.ventanas_por_workspace;
                        }
                    }

                    if (datos.ventana_titulo !== undefined) root.ventanaTitulo = datos.ventana_titulo;
                    if (datos.ventana_clase  !== undefined) root.ventanaClase  = datos.ventana_clase;
                    if (datos.ventana_icono  !== undefined) root.ventanaIcono  = datos.ventana_icono;
                    if (datos.redes)         root.redes         = datos.redes;
                    if (datos.brillo)        root.brillo        = datos.brillo;
                    if (datos.audio_salidas) root.audioSalidas  = datos.audio_salidas;
                    if (datos.audio_entradas)root.audioEntradas = datos.audio_entradas;
                    if (datos.volumen_actual !== undefined) root.volumenActual = datos.volumen_actual;
                    if (datos.volumen_mute   !== undefined) root.volumenMute   = datos.volumen_mute;
                    if (datos.bluetooth_devices) root.bluetoothDevices = datos.bluetooth_devices;
                    if (datos.bt_power_on !== undefined) root.btPowerOn = datos.bt_power_on;
                } catch(e) { 
                    console.log("Error parseando JSON:", e);
                }
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
                readonly property var monitorWorkspaceIds: root.workspacesPorMonitor[modelData.name] || []
                readonly property int monitorActiveIndex: {
                    var idx = monitorWorkspaceIds.indexOf(monitorWorkspace);
                    return idx >= 0 ? idx : 0;
                }

                anchors.top: true; anchors.left: true; anchors.right: true
                implicitHeight: Math.max(50, statusBar.height)
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: 50
                color: "transparent"

                WorkspaceBar {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    monitorWorkspaces: root.todosLosWorkspaces
                    activeWorkspace: root.workspaces[modelData.name] ?? 0
                    ventanasPorWorkspace: root.ventanasPorWorkspace
                }

                DynamicIsland {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: (50 - height) / 2
                    hora: root.horaSistema
                    fecha: root.fechaSistema
                    ventanaTitulo: root.ventanaTitulo
                    ventanaClase: root.ventanaClase
                    ventanaIcono: root.ventanaIcono
                    panelWindow: panelWin
                    screenGeometry: Qt.rect(modelData.x, modelData.y, modelData.width, modelData.height)
                }

                StatusBar {
                    id: statusBar
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    porcentajeBateria: root.porcentajeBateria
                    modelRedes: root.redes
                    modelBrillo: root.brillo
                    modelAudioSalidas: root.audioSalidas
                    modelAudioEntradas: root.audioEntradas
                    volumenActual: root.volumenActual
                    volumenMute: root.volumenMute
                    modelBluetoothDevices: root.bluetoothDevices
                    btPowerOn: root.btPowerOn
                    screenGeometry: Qt.rect(modelData.x, modelData.y, modelData.width, modelData.height)
                    panelWindow: panelWin
                }
            }
        }
    }
}
