import QtQuick

Item {
    id: root
    property real value: 0.5
    property color accentColor: "#7aa2f7"
    property alias pressed: mouseArea.pressed
    signal moved(real newValue)

    implicitWidth: 200
    implicitHeight: 28

    // Track background
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 3; radius: 2
        color: "#24283b"

        // Fill
        Rectangle {
            width: parent.width * root.value
            height: parent.height; radius: 2
            color: root.accentColor
        }
    }

    // Handle
    Rectangle {
        x: parent.width * root.value - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 14; height: 14; radius: 7
        color: root.accentColor
    }

    // Interaction area
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPositionChanged: mouse => {
            if (pressed) {
                var newValue = Math.max(0, Math.min(1, mouse.x / parent.width))
                root.moved(newValue)
            }
        }
        onClicked: mouse => {
            var newValue = Math.max(0, Math.min(1, mouse.x / parent.width))
            root.moved(newValue)
        }
        onWheel: {
            var step = 0.05
            var newValue = root.value + (wheel.angleDelta.y > 0 ? step : -step)
            root.moved(Math.max(0, Math.min(1, newValue)))
        }
    }
}

