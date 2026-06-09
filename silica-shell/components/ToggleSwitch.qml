import QtQuick

Rectangle {
    id: root
    width: 40; height: 22; radius: 11
    property bool checked: false
    signal toggled()

    color: checked ? "#7aa2f7" : "#2f334d"
    border.color: checked ? "#89b4fa" : "#3b4261"; border.width: 1

    Rectangle {
        x: root.checked ? 20 : 2
        anchors.verticalCenter: parent.verticalCenter
        width: 18; height: 18; radius: 9; color: "#c0caf5"
        Behavior on x { NumberAnimation { duration: 120 } }
    }

    MouseArea { anchors.fill: parent; onClicked: root.toggled() }
}
