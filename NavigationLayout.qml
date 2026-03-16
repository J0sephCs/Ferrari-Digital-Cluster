import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import ferrari
import QtLocation
import QtPositioning

Item {
    id: navContainer
    anchors.fill: parent

    // 1. THE SOURCE MAP (Invisible)
    Map {
        id: navMap
        anchors.fill: parent
        visible: false
        center: QtPositioning.coordinate(vehicleLat, vehicleLon)

        property real vehicleLat: 37.7749
        property real vehicleLon: -122.4194
        zoomLevel: 14
        property int currentTargetIndex: 1
        property var routePoints: [
            {
                lat: 37.7941,
                lon: -122.3951
            } // Start: Ferry Building
            ,
            {
                lat: 37.7915,
                lon: -122.3985
            } // Market & 1st
            ,
            {
                lat: 37.7842,
                lon: -122.4075
            } // Market & 4th
            ,
            {
                lat: 37.7770,
                lon: -122.4165
            } // Market & 9th (Preparing to turn)
            ,
            {
                lat: 37.7755,
                lon: -122.4182
            } // RIGHT TURN onto 9th St
            ,
            {
                lat: 37.7725,
                lon: -122.4145
            } // Driving down 9th
            ,
            {
                lat: 37.7710,
                lon: -122.4128
            } // LEFT TURN onto Mission St
            ,
            {
                lat: 37.7750,
                lon: -122.4080
            } // Driving down Mission
            ,
            {
                lat: 37.7800,
                lon: -122.4020
            } // Mission & 3rd
            ,
            {
                lat: 37.7840,
                lon: -122.3970
            } // Mission & Main
            ,
            {
                lat: 37.7875,
                lon: -122.3925
            }  // Heading toward the Embarcadero
        ]

        MapPolyline {
            id: routeHighlight
            line.width: 1.5
            line.color: "#ffbf00" // Gold color
            z: 10

            // We create the path by mapping the routePoints array into coordinates
            path: {
                var coords = [];
                // Only render from the current target index to the end
                for (var i = navMap.currentTargetIndex - 1; i < navMap.routePoints.length; i++) {
                    // Safety check for index -1
                    let idx = Math.max(0, i);
                    coords.push(QtPositioning.coordinate(navMap.routePoints[idx].lat, navMap.routePoints[idx].lon));
                }
                return coords;
            }
        }

        activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

        plugin: Plugin {
            name: "osm"
            PluginParameter {
                name: "osm.mapping.custom.host"
                value: "https://a.basemaps.cartocdn.com/dark_all/"
            }
        }

        Timer {
            interval: 16
            running: true
            repeat: true
            onTriggered: {
                let target = navMap.routePoints[navMap.currentTargetIndex];

                let dLat = target.lat - navMap.vehicleLat;
                let dLon = target.lon - navMap.vehicleLon;
                let distance = Math.sqrt(dLat * dLat + dLon * dLon);

                if (distance < 0.0001) {
                    // Move to next waypoint. If at end, stop or loop.
                    if (navMap.currentTargetIndex < navMap.routePoints.length - 1) {
                        navMap.currentTargetIndex++;
                    } else {
                        navMap.currentTargetIndex = 0; // Loop back to start

                        // Immediately move coordinates to the start point
                        // to prevent the marker from "gliding" back across the map
                        navMap.vehicleLat = navMap.routePoints[0].lat;
                        navMap.vehicleLon = navMap.routePoints[0].lon;
                    }
                } else {

                    navMap.vehicleLat += dLat * 0.045;
                    navMap.vehicleLon += dLon * 0.045;

                    navMap.center = QtPositioning.coordinate(navMap.vehicleLat, navMap.vehicleLon);

                    // Calculate the bearing for the rotation
                    let nextAngle = Math.atan2(dLon, dLat) * (180 / Math.PI);

                    // Smooth rotation interpolation (prevents jerky turns)
                    let rawDiff = nextAngle - triangleMarker.rotation;
                    let smoothDiff = Math.atan2(Math.sin(rawDiff * Math.PI / 180), Math.cos(rawDiff * Math.PI / 180)) * 180 / Math.PI;
                    triangleMarker.rotation += smoothDiff * 0.1;

                    var screenPos = navMap.fromCoordinate(navMap.center, false);
                    triangleMarker.x = screenPos.x - triangleMarker.width / 2;
                    triangleMarker.y = screenPos.y - triangleMarker.height / 2;
                }
            }
        }
    }

    // 2. THE CLUSTER SHAPE (Mask Template)
    Image {
        id: maskImage
        source: "assets/cluster.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    // 3. THE RENDERED MASKED MAP
    Item {
        id: maskedMapClipContainer
        anchors.fill: parent
        height: parent.height - 85
        clip: true

        OpacityMask {
            id: maskedMap
            anchors.fill: parent
            source: navMap
            maskSource: maskImage
        }
    }

    // 4. REFINED OVERLAY UI
    Item {
        id: overlayUI
        anchors.fill: parent

        // --- DYNAMIC VEHICLE MARKER ---
        // Changed from MapQuickItem to a standard Shape on the UI layer
        Shape {
            id: triangleMarker
            width: 30
            height: 30 // Increased height for proper triangle geometry
            vendorExtensionsEnabled: true
            z: 10 // Ensure it's above the map

            ShapePath {
                strokeColor: "#1ea7ff"
                strokeWidth: 2
                fillColor: "#4000f2ff"

                startX: 0
                startY: 30
                PathLine {
                    x: 15
                    y: 0
                }
                PathLine {
                    x: 30
                    y: 30
                }
                PathLine {
                    x: 0
                    y: 30
                }
            }
        }

        // --- TIME & DATE DISPLAY ---
        Item {
            id: timeDateDisplay
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            

            anchors.leftMargin: 440
            width: timeRow.width + 60
            height: timeRow.height + 10

            // Soft glass background
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: "black"
                opacity: 0.45
            }

            // Subtle glow (very light)
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: "black"
                opacity: 0.18

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    color: "black"
                    radius: 18
                    samples: 32
                    spread: 0.05
                }
            }

            Row {
                id: timeRow
                spacing: 64
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.centerIn: parent

                anchors.top: parent.top
                anchors.topMargin: 6

                Text {
                    id: timeText
                    text: Qt.formatTime(new Date(), "hh:mm AP")
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        color: "white"
                        radius: 4
                        samples: 8
                    }
                }

                // DIRECTION (The New Middle Part)
                Text {
                    id: directionText
                    text: "NW" // You can bind this to your compass data
                    color: "#1ea7ff" // Blue
                    font.pixelSize: 26
                    font.bold: true
                    font.letterSpacing: 2
                    verticalAlignment: Text.AlignVCenter

                    // Subtle glow for the direction specifically
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#1ea7ff"
                        shadowBlur: 0.5
                    }
                }

                Text {
                    id: dateText
                    text: Qt.formatDate(new Date(), "dddd, MMMM d")
                    color: "white"
                    font.pixelSize: 20
                    font.weight: Font.Light
                    verticalAlignment: Text.AlignVCenter

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        color: "white"
                        radius: 4
                        samples: 8
                    }
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    timeText.text = Qt.formatTime(new Date(), "hh:mm AP");
                    dateText.text = Qt.formatDate(new Date(), "dddd, MMMM d");
                }
            }
        }

        // --- SPEED & MODE BOXES ---
        Rectangle {
            id: speedBox
            width: 140
            height: 70
            x: 210
            y: 180
            color: "transparent"
            border.color: "#44FFFFFF"
            radius: 4

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 10   
                spacing: -4             

                Text {
                    id: mphText
                    text: "40"
                    color: "white"
                    font.pixelSize: 32
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "mph"
                    color: "white"
                    font.pixelSize: 10
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Rectangle {
            id: performanceMini
            width: 140
            height: 50
            x: parent.width - 335
            y: 190
            color: "transparent"
            border.color: "#44FFFFFF"
            radius: 4
            Text {
                text: "ETA 8 min"
                color: "white"
                font.pixelSize: 14
                font.bold: true
                anchors.centerIn: parent
            }
        }

        // --- ODOMETER PILL ---
        Item {
            id: odometerContainer
            width: 245
            height: 60
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 22
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                topLeftRadius: 25
                topRightRadius: 25
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "transparent" // 50% opacity blue
                    }
                    GradientStop {
                        position: 1.0
                        color: "#883a5a7d" // 50% opacity blue
                    }
                }
                // border.color: "#6a8fb3"
                border.color: "#226a8fb3"
                border.width: 1
            }

            Text {
                text: "ODO 12,450 mi"
                color: "#EBB04D"
                font.pixelSize: 22
                anchors.centerIn: parent
                style: Text.Outline
                styleColor: "black"
            }
        }

        // --- INDICATORS (Bottom Right of Odometer) ---
        Row {
            id: indicatorRow
            spacing: 75 // Reduced spacing slightly to prevent it from running off-screen

            // Position relative to the Odometer Pill
            anchors.left: odometerContainer.right
            anchors.leftMargin: 190
            anchors.bottom: odometerContainer.bottom
            anchors.bottomMargin: 5 // Aligns bottom edge with the pill


            Shortcut { sequence: "X"; onActivated: pImg.isOn = !pImg.isOn }
            Shortcut { sequence: "C"; onActivated: lightImg.isOn = !lightImg.isOn }
            Shortcut { sequence: "B"; onActivated: seatBeltImg.isOn = !seatBeltImg.isOn }
            Shortcut { sequence: "V"; onActivated: parkingImgLight.isOn = !parkingImgLight.isOn }


            Image {
                id: pImg
                property bool isOn: false
                source: isOn ? "assets/Indicators/p_red.svg" : "assets/Indicators/p.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: lightImg
                property bool isOn: false
                source: isOn ? "assets/Indicators/Lights.svg" : "assets/Indicators/Light_White.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: parkingImgLight
                property bool isOn: false
                source: isOn ? "assets/Indicators/parkingLight.svg" : "assets/Indicators/parkingLightWhite.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: seatBeltImg
                property bool isOn: false
                source: isOn ? "assets/Indicators/seatBeltRed.svg" : "assets/Indicators/seatBelt.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }
        }

        // --- LEFT INDICATORS (Left of Odometer) ---
        Row {
            id: leftIndicatorRow
            spacing: 75 // Adjusted for better fit

            // Align the right side of this row to the left side of the odo pill
            anchors.right: odometerContainer.left
            anchors.rightMargin: 190
            anchors.bottom: odometerContainer.bottom
            anchors.bottomMargin: 5 // Matches the right-side indicators


            
            Shortcut { sequence: "W"; onActivated: warningImg.isOn = !warningImg.isOn }
            Shortcut { sequence: "E"; onActivated: fogImg.isOn = !fogImg.isOn }
            Shortcut { sequence: "R"; onActivated: lowBeamImg.isOn = !lowBeamImg.isOn }
            Shortcut { sequence: "T"; onActivated: parkingImg.isOn = !parkingImg.isOn }


            Image {
                id: warningImg
                property bool isOn: false
                source: isOn ? "assets/Indicators/warningRed.svg" : "assets/Indicators/warning.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: fogImg
                property bool isOn: false
                source: isOn ? "assets/Indicators/fogLightRed.svg" : "assets/Indicators/fogLight.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: lowBeamImg
                property bool isOn: false
                source: isOn ? "assets/Indicators/lowBeam.svg" : "assets/Indicators/lowBeamWhite.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: parkingImg
                property bool isOn: false
                source: isOn ? "assets/Indicators/parkingLight.svg" : "assets/Indicators/parkingLightWhite.svg"
                width: 35
                height: 35
                fillMode: Image.PreserveAspectFit
            }
        }

        // --- VERTICAL GAS GAUGE ---
        Item {
            id: gasGaugeContainer
            width: 25
            height: 180
            anchors.right: parent.right
            anchors.rightMargin: 140
            anchors.verticalCenter: parent.verticalCenter
            property real fuelLevel: 0.90 

            // Gauge Background (Glass Track)
            Rectangle {
                id: track
                anchors.fill: parent
                color: "#22FFFFFF"
                border.color: "#44FFFFFF"
                border.width: 1

                radius: width / 2
            }

            // Gauge Fill (Fuel Level)
            Rectangle {
                id: fuelFill
                width: parent.width - 6
                height: (parent.height - 6) * gasGaugeContainer.fuelLevel

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                anchors.horizontalCenter: parent.horizontalCenter

                // Rounded ends match width
                radius: width / 2

                color: gasGaugeContainer.fuelLevel > 0.2 ? "#1ea7ff" : "#FF3B30"

                Behavior on height {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                }
            }


            // "F" and "E" Labels
            Text {
                text: "F"
                color: "white"
                font.pixelSize: 14
                font.bold: true
                anchors.bottom: parent.top
                anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: emptyLabel
                text: "E"
                color: gasGaugeContainer.fuelLevel < 0.15 ? "#FF3B30" : "white"
                font.pixelSize: 14
                font.bold: true
                anchors.top: parent.bottom
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Image {
                id: fuelIcon
                source: "assets/Indicators/fuel.svg"
                width: 18 
                height: 18
                fillMode: Image.PreserveAspectFit

                anchors.left: emptyLabel.right
                anchors.leftMargin: 25
                anchors.verticalCenter: emptyLabel.verticalCenter

                layer.enabled: gasGaugeContainer.fuelLevel < 0.2
                layer.effect: ColorOverlay {
                    color: "#FF3B30"
                }
            }
        }




        // --- VERTICAL GAS GAUGE ---
        Item {
            id: tempGaugeContainer
            width: 25
            height: 180
            anchors.left: parent.left
            anchors.leftMargin: 140
            anchors.verticalCenter: parent.verticalCenter
            property real fuelLevel: 0.45 

            // Gauge Background (Glass Track)
            Rectangle {
                id: tempTrack
                anchors.fill: parent
                color: "#22FFFFFF"
                border.color: "#44FFFFFF"
                border.width: 1

                // Full rounded ends (pill shape)
                radius: width / 2
            }

            // Gauge Fill (Fuel Level)
            Rectangle {
                id: tempFuelFill
                width: parent.width - 6
                height: (parent.height - 6) * tempGaugeContainer.fuelLevel

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                anchors.horizontalCenter: parent.horizontalCenter

                // Rounded ends match width
                radius: width / 2

                color: tempGaugeContainer.fuelLevel > 0.2 ? "#1ea7ff" : "#FF3B30"

                Behavior on height {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                }
            }


            Text {
                text: "H"
                color: "white"
                font.pixelSize: 14
                font.bold: true
                anchors.bottom: parent.top
                anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: coldLabel
                text: "C"
                color: tempGaugeContainer.fuelLevel < 0.15 ? "#FF3B30" : "white"
                font.pixelSize: 14
                font.bold: true
                anchors.top: parent.bottom
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Image {
                id: tempIcon
                source: "assets/Icons/oil-temp.png"
                width: 18 
                height: 18
                fillMode: Image.PreserveAspectFit

                // Move to the right of 'E'
                anchors.right: coldLabel.left
                anchors.rightMargin: 25
                anchors.verticalCenter: coldLabel.verticalCenter

                layer.enabled: tempGaugeContainer.fuelLevel < 0.2
                layer.effect: ColorOverlay {
                    color: "#FF3B30"
                }
            }
        }

    }
}
