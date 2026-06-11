import QtQuick

Text {
    property string date
    property string dateLong: ""
    property bool expanded: false
    text: expanded ? dateLong : date
    color: "#ffffff"
    font.bold: true
    font.pixelSize: 14
    anchors.verticalCenter: parent.verticalCenter
}
