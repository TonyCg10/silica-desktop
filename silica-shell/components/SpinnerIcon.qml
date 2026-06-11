import QtQuick

Item {
    id: root
    property bool spinning: false
    property color activeColor: "#ffffff"
    property color idleColor: "#ffffff"
    property string icon: "\ue036"
    property real size: 12

    implicitWidth: size + 4
    implicitHeight: size + 4

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        font.family: "Phosphor-Bold"
        font.pixelSize: root.size
        color: root.spinning ? root.activeColor : root.idleColor
    }

    SequentialAnimation {
        id: spinAnim
        running: root.spinning
        loops: Animation.Infinite

        NumberAnimation {
            target: iconText; property: "rotation"
            from: 0; to: 360
            duration: 800
            easing.type: Easing.Linear
        }
    }

    Connections {
        target: root
        function onSpinningChanged() {
            if (!root.spinning) {
                spinAnim.stop()
                iconText.rotation = 0
            }
        }
    }
}
