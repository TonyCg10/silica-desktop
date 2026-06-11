import QtQuick

Item {
    id: root
    property string icon: ""
    property string title: ""
    property color iconColor: "#ffffff"

    default property alias actions: actionsSlot.data

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    height: 28

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            text: root.icon
            color: root.iconColor
            font.family: "Phosphor-Bold"
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.title
            color: "#c0caf5"
            font.pixelSize: 14
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        id: actionsSlot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}
