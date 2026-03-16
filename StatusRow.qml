import QtQuick

Item {
    width: parent.width
    height: 36   // ⬆ more height for value-above-bar layout

    property string label
    property string value
    property real level: 0.7

   

    Row {
        anchors.fill: parent
        spacing: 6

        // Label (left)
        Text {
            id: labelText 
            text: label
            width: 25
            color: "#9fb3c8"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
        }

        // Bar + Value (right)
        Column {
            width: 110
            spacing: 2

            // Value ABOVE the bar
            Text {
                text: value
                width: parent.width
                color: "white"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }

            // Bar
            Rectangle {
                id: bar
                width: 90
                height: 6
                radius: 3
                color: "red"   // background bar

                Rectangle {
                    width: parent.width * level
                    height: parent.height
                    radius: 3
                    color: "#4da6ff"
                }
            }
        }
    }
}

