import QtQuick
import "../components" as Components

Row {
    id: control

    required property var monitorWorkspaces
    required property var ventanasPorWorkspace
    required property int activeWorkspace

    spacing: 8

    function getAppIcon(clientClass) {
        return Components.IconSystem.getAppIcon(clientClass)
    }

    function isIconPath(icon) {
        if (!icon || icon.length === 0) return false;
        return icon.startsWith("/") || icon.startsWith("file://") || icon.indexOf(".") !== -1;
    }

    function wsHas(wsId) {
        if (!ventanasPorWorkspace) return false;
        let info = ventanasPorWorkspace[wsId];
        return !!(info && info.clase !== "");
    }

    function iconFor(wsId) {
        if (!ventanasPorWorkspace) return "";
        let info = ventanasPorWorkspace[wsId];
        if (!info || !info.icono) return "";
        if (info.icono.startsWith("/")) return "file://" + info.icono;
        if (isIconPath(info.icono)) return "image://theme/" + info.icono;
        return "";
    }

    Repeater {
        model: control.monitorWorkspaces
        delegate: Component {
            Item {
                required property int modelData

                readonly property bool active: control.activeWorkspace == modelData
                readonly property bool hasWin: control.wsHas(modelData)
                readonly property string ico: control.iconFor(modelData)
                readonly property string fallback: hasWin && ventanasPorWorkspace[modelData] ? control.getAppIcon(ventanasPorWorkspace[modelData].clase) : ""

                width: 24
                height: 24

                Rectangle {
                    anchors.centerIn: parent
                    width: hasWin ? 24 : (active ? 12 : 8)
                    height: hasWin ? 24 : (active ? 12 : 8)
                    radius: hasWin ? 6 : width / 2
                    color: active ? "#24283b" : (hasWin ? "transparent" : "#414868")

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Image {
                    id: img
                    anchors.centerIn: parent
                    width: 16; height: 16
                    sourceSize.width: 16; sourceSize.height: 16
                    source: ico
                    visible: ico.length > 0 && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: fallback
                    color: "#ffffff"
                    font.family: Components.IconSystem.fontFamily
                    font.pixelSize: 13
                    visible: hasWin && (ico.length === 0 || img.status !== Image.Ready)
                }
            }
        }
    }
}
