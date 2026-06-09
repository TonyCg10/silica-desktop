import QtQuick

Row {
    // Definimos qué necesita recibir este componente externamente
    required property int activeWorkspace 
    
    spacing: 8

    Repeater {
        model: 4
        delegate: Component {
            Rectangle {
                required property int index

                width: activeWorkspace === (index + 1) ? 24 : 8 
                height: 8
                radius: 4
                color: activeWorkspace === (index + 1) ? "#7aa2f7" : "#414868" 

                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } } 
                Behavior on color { ColorAnimation { duration: 200 } } 
            }
        }
    }
}