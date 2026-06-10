import QtQuick

// Expanding pill container for status bar menus.
// Place the icon content and the menu component as children (default alias → pillContent).
Rectangle {
    id: root

    // ── API ──
    property string menuKey: ""
    property string menuAbierto: ""
    property string menuAnterior: ""
    property int expandedWidth: 320

    // Signal helpers to forward to parent timers
    signal hoverEntered()
    signal hoverExited()

    // Children go into the content area (icon + embedded menu)
    default property alias pillContent: contentArea.data

    // ── State ──
    readonly property bool exp: menuAbierto === menuKey || menuAnterior === menuKey

    // ── Geometry ──
    width:  exp ? expandedWidth : 34
    height: exp ? Math.max(34, contentArea.childrenRect.height + 10) : 34
    radius: exp ? 12 : 17
    color: "#1f2335"
    border.color: "#2f334d"; border.width: 1
    clip: true

    Behavior on width  { SmoothedAnimation { velocity: 1200 } }
    Behavior on height { SmoothedAnimation { velocity: 1200 } }
    Behavior on radius { NumberAnimation   { duration: 220; easing.type: Easing.OutCubic } }

    // Content area — icon + menu are placed here by the parent
    Item {
        id: contentArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: childrenRect.height
    }

    // Hover overlay — propagates events through to the embedded menu when open
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: root.hoverEntered()
        onExited:  root.hoverExited()
        onClicked: (mouse) => mouse.accepted = !root.exp
        onPressed: (mouse) => mouse.accepted = !root.exp
    }
}
