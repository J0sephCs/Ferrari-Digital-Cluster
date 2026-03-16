import QtQuick

Row {
    id: root
    spacing: 22

    // ===== API =====
    property string iconSource
    property string value
    property real level: 0.7        

    // ===== ICON =====
    Image {
        source: iconSource
        width: 24
        height: 24
        fillMode: Image.PreserveAspectFit
        opacity: 0.9
        anchors.verticalCenter: parent.verticalCenter
    }

    // ===== VALUE =====
    Text {
        width: 30
        text: value
        color: "white"
        font.pixelSize: 14
        font.bold: true
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }

    // ===== BAR =====
    Rectangle {
        width: 85
        height: 6
        radius: 3
        color: "#1a1a1a"
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: parent.width * root.level
            height: parent.height
            radius: 3
            color: "#4da6ff"

            Behavior on width {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}

