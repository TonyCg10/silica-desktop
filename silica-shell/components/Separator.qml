import QtQuick

// Thin horizontal divider line. Use margins to control side padding.
Rectangle {
    property real margins: 16
    x: margins
    width: parent.width - margins * 2
    height: 1
    color: "#2f334d"
}
