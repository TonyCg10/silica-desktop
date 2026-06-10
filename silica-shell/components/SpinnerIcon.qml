import QtQuick

// Reusable spinning icon. Shows a RotationAnimator when `spinning` is true.
Item {
    id: root
    property bool spinning: false
    property color activeColor: "#9ece6a"
    property color idleColor: "#7aa2f7"
    property string icon: "\uF0453"
    property real size: 12

    implicitWidth: size + 4
    implicitHeight: size + 4

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.size
        color: root.spinning ? root.activeColor : root.idleColor
        transformOrigin: Item.Center

        RotationAnimator on rotation {
            running: root.spinning
            from: 0; to: 360
            duration: 800
            loops: Animation.Infinite
        }
    }
}
