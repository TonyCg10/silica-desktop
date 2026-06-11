import QtQuick
import "../components" as Components

Row {
    id: root
    property string windowTitle
    property string windowClass
    property string windowIcon: ""
    property bool isWindowVisible: false
    property alias tituloImplicitWidth: tituloText.implicitWidth
    property int iconWidth: windowIconItem.status === Image.Ready ? 18 : fallbackIcon.implicitWidth
    spacing: 8
    opacity: isWindowVisible ? 1 : 0
    
    // Nueva propiedad para controlar el estado visual expandido
    property bool expanded: false

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    function getAppIcon(clientClass) {
        return Components.IconSystem.getAppIcon(clientClass)
    }

    function isIconPath(icon) {
        if (icon.length === 0) return false
        return icon.startsWith("/") || icon.startsWith("file://") || icon.indexOf(".") !== -1
    }

    Image {
        id: windowIconItem
        anchors.verticalCenter: parent.verticalCenter
        visible: isIconPath(root.windowIcon) && status === Image.Ready
        source: {
            if (!isIconPath(root.windowIcon)) return ""
            if (root.windowIcon.startsWith("/"))
                return "file://" + root.windowIcon
            return "image://theme/" + root.windowIcon
        }
        width: 18; height: 18
        sourceSize.width: 18; sourceSize.height: 18
    }

    Text {
        id: fallbackIcon
        anchors.verticalCenter: parent.verticalCenter
        text: getAppIcon(root.windowClass)
        color: "#ffffff"
        font.family: Components.IconSystem.fontFamily
        font.pixelSize: 15
        visible: !isIconPath(root.windowIcon) || windowIconItem.status !== Image.Ready
        font.capitalization: Font.AllLowercase
    }

    Text {
        id: tituloText
        anchors.verticalCenter: parent.verticalCenter
        text: root.windowTitle.length > 0 ? root.windowTitle : root.windowClass
        color: "#ffffff"
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
        font.capitalization: Font.AllLowercase
        
        // Al estar expandido permitimos que ocupe mucho más espacio antes de recortarse
        width: Math.min(implicitWidth, root.expanded ? 480 : 280)
        
        Behavior on width {
            NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
        }
    }
}