import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: gauge
    width: 300
    height: 300
    property real minValue: 0
    property real maxValue: 150
    property real currentValue: 0

    // ----------------------------
    // Background gauge image
    // ----------------------------
    Image {
        id: backgroundAsset
        source: "assets/gauge.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit

        // ----------------------------
        // Canvas for ticks and arcs
        // ----------------------------
        Canvas {
            id: ticksCanvas
            anchors.fill: parent
            anchors.rightMargin: 23

            property int minorTicksPerStep: 40
            property real minValue: 0
            property real maxValue: 150   
            property real sweepAngle: 230
            property real startAngle: -140

            function degreesToRadians(deg) {
                return deg * Math.PI / 180;
            }
            function valueToAngle(value) {
                return startAngle + (value - minValue) / (maxValue - minValue) * sweepAngle;
            }

            onPaint: {
                var leftRotation = 40; 

                var ctx = getContext("2d");
                ctx.reset();
                var center = width / 2;
                var radiusOuter = center * 0.93; 
                var radiusInnerMinor = center * 0.97; 

                var radiusArc = center * 0.94;   // arc slightly inside ticks

                // --- ARC ---
                var startDeg = valueToAngle(minValue) - 90 - leftRotation;
                var endDeg = valueToAngle(maxValue) - 90 - leftRotation;

                var redStartValue = minValue + (maxValue - minValue) * 0.76;
                var redStartDeg = valueToAngle(redStartValue) - 90 - leftRotation;

                var blackEndValue = minValue + (maxValue - minValue) * 0.15;
                var blackEndDeg = valueToAngle(blackEndValue) - 90 - leftRotation;

                ctx.beginPath();
                ctx.strokeStyle = "#000000";
                ctx.lineWidth = 1;
                ctx.arc(center, center, radiusArc, degreesToRadians(startDeg), degreesToRadians(blackEndDeg), false);
                ctx.stroke();

                ctx.beginPath();
                ctx.strokeStyle = "#9995A4";    // subtle white
                ctx.lineWidth = 1;                // arc thickness
                ctx.arc(center, center, radiusArc, degreesToRadians(blackEndDeg), degreesToRadians(redStartDeg), false);
                ctx.stroke();

                // --- RED ARC (70% → 100%) ---
                ctx.beginPath();
                ctx.strokeStyle = "#D4001A";   // Ferrari-style red
                ctx.lineWidth = 1;            // slightly thicker for emphasis
                ctx.arc(center, center, radiusArc, degreesToRadians(redStartDeg), degreesToRadians(endDeg), false);
                ctx.stroke();

                // // Minor ticks only
                var step = (maxValue - minValue) / minorTicksPerStep;
                for (var i = 0; i <= minorTicksPerStep; i++) {
                    var value = minValue + i * step;
                    var angle = degreesToRadians(valueToAngle(value) - 90 - leftRotation);

                    if (value <= blackEndValue) {
                        ctx.strokeStyle = "#000000";   // black
                        ctx.lineWidth = 2.5;
                    } else if (value >= redStartValue) {
                        ctx.strokeStyle = "#D4001A";   // red
                        ctx.lineWidth = 2.5;
                    } else {
                        ctx.strokeStyle = "#9995A4";     // mid-range
                        ctx.lineWidth = 2.5;
                    }
                    var x1 = center + radiusOuter * Math.cos(angle);
                    var y1 = center + radiusOuter * Math.sin(angle);
                    var x2 = center + radiusInnerMinor * Math.cos(angle);
                    var y2 = center + radiusInnerMinor * Math.sin(angle);

                    ctx.beginPath();
                    ctx.moveTo(x1, y1);
                    ctx.lineTo(x2, y2);
                    ctx.stroke();
                }
            }
        }

        // ----------------------------
        // Center Decorations + Needle
        // ----------------------------
        Item {
            id: centerArea
            width: 215
            height: 215
            anchors.centerIn: parent

            Canvas {
                anchors.fill: parent
                anchors.rightMargin: 23
                anchors.bottomMargin: 25
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#9995A4";
                    ctx.lineWidth = 1.5;
                    ctx.setLineDash([1, 4]);
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, width / 2 - 5, 0, 2 * Math.PI);
                    ctx.stroke();
                }
            }

            // Crosshairs
            Rectangle {
                width: 1
                height: 200
                color: "#33FFFFFF"
                anchors.centerIn: parent
            }
            Rectangle {
                width: 200
                height: 1
                color: "#33FFFFFF"
                anchors.centerIn: parent
            }

            // Needle
            Image {
                id: needle
                source: "assets/needle_red.svg"
                width: 10
                height: 165
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                transformOrigin: Item.Bottom

                // Define start angle and sweep angle
                property real needle_startAngle: 185
                property real needle_sweepAngle: 150
                property real needle_maxSpeed: 200

                property real maxRotation: 410


                rotation: Math.min(needle_startAngle + vehicleState.speed * 2.1, maxRotation)

                Behavior on rotation {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                layer.enabled: true
                layer.effect: Glow {
                    radius: 12
                    samples: 32
                    color: "red"
                    spread: 0.35
                }
            }

            // Pivot circle
            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: "#111111"
                border.color: "#FFD700"
                border.width: 1
                anchors.centerIn: parent
            }
        }

        // ----------------------------
        // HUD overlay: speed + gear
        // ----------------------------
        Image {
            id: hudOverlay
            source: "assets/gearSpeed.png"
            width: gauge.width * 0.46
            height: 200
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenterOffset: gauge.width * 0.21
            anchors.verticalCenterOffset: 18
            z: 10
            opacity: 0.95
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // MPH label
            Text {
                id: mphLabel
                text: Math.round(vehicleState.speed) + " mph"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 3
                anchors.horizontalCenterOffset: 25
                font.pixelSize: 25
                font.weight: Font.Bold
                font.family: "Eurostile"
                color: "#FFFFFF"
            }

            // RPM label
            Text {
                id: kmhLabel
                text: Math.round(vehicleState.speed / 10) + " RPM"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 35
                anchors.horizontalCenterOffset: 25
                font.pixelSize: 20
                font.weight: Font.Normal
                font.family: "Eurostile"
                color: "#FFFFFF"

                Text {
                    text: "x1000"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top

                    anchors.topMargin: 25
                    anchors.horizontalCenterOffset: 25
                    font.pixelSize: 13
                    font.weight: Font.Normal
                    font.family: "Eurostile"
                    color: "black"
                }
            }

            // Gear label
            Text {
                id: gearLabel
                text: vehicleState.gearText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 25
                anchors.horizontalCenterOffset: -50
                font.pixelSize: 40
                font.weight: Font.Bold
                font.family: "Eurostile"

                color: {
                    switch (vehicleState.gearText) {
                    case "P":
                        return "#FFD700";
                    case "S":
                        return "#D4001A";
                    default:
                        return "#FFFFFF";
                    }
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8
                    samples: 16
                    color: "#80000000"
                }
            }

            // AUTO text
            Text {
                text: "AUTO"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                anchors.horizontalCenterOffset: -50
                font.pixelSize: 15
                font.weight: Font.Light
                font.family: "Eurostile"
                color: "#FFFFFF"
            }
        }
    }
}
