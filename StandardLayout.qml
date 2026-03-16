import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import ferrari
import QtLocation
import QtPositioning

Item {
    anchors.fill: parent

    Image {
        id: clusterImage
        anchors.centerIn: parent
        source: "assets/cluster.png"
        fillMode: Image.PreserveAspectFit

        // =========================
        // LEFT NAVIGATION MAP PANEL
        // =========================
        Rectangle {
            id: mapPanel
            width: 390
            height: 300
            opacity: 0.95

            radius: 16
            clip: true
            color: "transparent"

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 70
            anchors.right: rpmGauge.left
            anchors.rightMargin: 20

            // Map itself
            Map {
                id: navMap
                anchors.fill: parent
                zoomLevel: 16
                // Updated Start: Top of Lombard Street
                property real vehicleLat: 37.8106
                property real vehicleLon: -122.4771
                center: QtPositioning.coordinate(vehicleLat, vehicleLon)

                property int currentTargetIndex: 1
                property var routePoints: [
                    {
                        lat: 37.8106,
                        lon: -122.4771
                    } // Start: Fort Point / Marine Dr
                    ,
                    {
                        lat: 37.8085,
                        lon: -122.4760
                    } // Long Ave (Climbing the hill)
                    ,
                    {
                        lat: 37.8078,
                        lon: -122.4752
                    } // Joining US-101 Toll Plaza area
                    ,
                    {
                        lat: 37.8115,
                        lon: -122.4765
                    } // Entrance to the bridge span
                    ,
                    {
                        lat: 37.8199,
                        lon: -122.4786
                    } // Mid-span (Over the water)
                    ,
                    {
                        lat: 37.8250,
                        lon: -122.4795
                    } // North Tower
                    ,
                    {
                        lat: 37.8320,
                        lon: -122.4800
                    } // North end of bridge
                    ,
                    {
                        lat: 37.8325,
                        lon: -122.4790
                    }
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

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true

                    property real lastX
                    property real lastY

                    onPressed: mouse => {
                        lastX = mouse.x;
                        lastY = mouse.y;
                    }

                    onPositionChanged: mouse => {
                        if (mouse.buttons & Qt.LeftButton) {
                            let dx = mouse.x - lastX;
                            let dy = mouse.y - lastY;

                            navMap.pan(-dx, -dy);

                            lastX = mouse.x;
                            lastY = mouse.y;
                        }
                    }
                }

                WheelHandler {
                    target: navMap
                    onWheel: {
                        navMap.zoomLevel += wheel.angleDelta.y > 0 ? 0.4 : -0.4;
                    }
                }

                activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

                plugin: Plugin {
                    name: "osm"
                    // 1. Define the Dark Matter tile server
                    PluginParameter {
                        name: "osm.mapping.custom.host"
                        value: "https://a.basemaps.cartocdn.com/dark_all/"
                    }
                    // 2. Add required attribution for CARTO
                    // PluginParameter {
                    //     name: "osm.mapping.custom.copyright"
                    //     value: "Map tiles by Carto, under CC BY 3.0. Data by OpenStreetMap, under ODbL."
                    // }

                    PluginParameter {
                        name: "osm.mapping.highdpi_tiles"
                        value: true
                    }
                }


                


                MapQuickItem {
                    id: triangleMarker
                    coordinate: QtPositioning.coordinate(navMap.vehicleLat, navMap.vehicleLon)

                    // Defines which part of the triangle is placed on the coordinate
                    anchorPoint.x: triangleShape.width / 2
                    anchorPoint.y: triangleShape.height / 2

                    sourceItem: Shape {
                        id: triangleShape
                        width: 30
                        height: 20
                        vendorExtensionsEnabled: true // Smooths edges on some hardware

                        ShapePath {
                            strokeColor: "#1ea7ff" // Neon Cyan to pop on dark background
                            strokeWidth: 2
                            fillColor: "#4000f2ff" // Semi-transparent fill

                            // Start at the bottom left
                            startX: 0
                            startY: 30
                            PathLine {
                                x: 15
                                y: 0
                            }  // Top peak
                            PathLine {
                                x: 30
                                y: 30
                            } // Bottom right
                            PathLine {
                                x: 0
                                y: 30
                            } // Back to start
                        }
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
                            navMap.vehicleLat += dLat * 0.030;
                            navMap.vehicleLon += dLon * 0.030;

                            navMap.center = QtPositioning.coordinate(navMap.vehicleLat, navMap.vehicleLon);

                            // Calculate the bearing for the rotation
                            // We use the current movement vector to determine where the "nose" points
                            let nextAngle = Math.atan2(dLon, dLat) * (180 / Math.PI);

                            // Smooth rotation interpolation (prevents jerky turns)
                            let rawDiff = nextAngle - triangleShape.rotation;
                            let smoothDiff = Math.atan2(Math.sin(rawDiff * Math.PI / 180), Math.cos(rawDiff * Math.PI / 180)) * 180 / Math.PI;
                            triangleShape.rotation += smoothDiff * 0.1;
                        }
                    }
                }
            }

            // Seamless glow
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                opacity: 0.25
                radius: 16

                border.color: "#1ea7ff"
                border.width: 2
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    color: "#1ea7ff"
                    radius: 24
                    samples: 48
                    horizontalOffset: 0
                    verticalOffset: 0
                    spread: 0.2
                }

                // Glow pulse animation
                SequentialAnimation on opacity {
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 0.25
                        to: 0.55
                        duration: 1200
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: 0.55
                        to: 0.25
                        duration: 1200
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        //Indicators
        Row {
            id: indicatorRow
            spacing: 75
            anchors.top: mapPanel.bottom
            anchors.topMargin: 30

            anchors.left: mapPanel.left
            anchors.leftMargin: 5

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

        //Time & Date & Compass Display
        Item {
            id: timeDateDisplay
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 440

            width: timeRow.width + 60
            height: timeRow.height + 10

            // Soft glass background
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: "#060c18"
                opacity: 0.45
            }

            // Subtle glow (very light)
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: "blue"
                opacity: 0.18

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    color: "#1ea7ff"
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
                        color: "black"
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
                        color: "black"
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

        // ==========
        // RPM GAUGE
        // ==========
        Gauge {

            id: rpmGauge
            anchors.centerIn: parent
            width: 400
            height: 400
            minValue: 0
            maxValue: 10
            currentValue: vehicleState.rpm / 1000 
        }

        // ==================
        // RIGHT STATUS PANEL
        // ==================
        Rectangle {
            id: statusPanel
            width: 390
            height: 300
            radius: 16
            color: "black"
            opacity: 0.95

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 70
            anchors.left: rpmGauge.right
            anchors.leftMargin: 20

            // Glowing border effect
            Rectangle {
                id: glowFrame
                anchors.fill: parent
                color: "transparent"

                border.color: "#1ea7ff"
                border.width: 1
                radius: 16

                // Base transparency
                opacity: 0.25

                // Soft glow layer
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    color: "#1ea7ff"
                    radius: 16
                    samples: 48
                    horizontalOffset: 0
                    verticalOffset: 0
                    spread: 0.2
                }

                // Glow pulse animation
                SequentialAnimation on opacity {
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 0.25
                        to: 0.55
                        duration: 1200
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: 0.55
                        to: 0.25
                        duration: 1200
                        easing.type: Easing.InOutSine
                    }
                }
            }

            // Layout content
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 30

                Text {
                    text: "PERFORMANCE MODE"
                    color: "#60B45A"
                    font.pixelSize: 16
                    font.bold: true
                }

                Row {
                    width: parent.width
                    height: 180
                    spacing: 25

                    Column {
                        width: 160
                        spacing: 8

                        Text {
                            text: "Status overview"
                            color: "white"
                            font.pixelSize: 13
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Item {
                            width: 160
                            height: 150

                            Image {
                                source: "assets/vehicle_top_view.jpg"
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                opacity: 0.85
                            }

                            Repeater {
                                model: [
                                    {
                                        xF: 0.01,
                                        yF: 0.20
                                    },
                                    {
                                        xF: 0.75,
                                        yF: 0.20
                                    },
                                    {
                                        xF: 0.01,
                                        yF: 0.70
                                    },
                                    {
                                        xF: 0.75,
                                        yF: 0.70
                                    }
                                ]
                                delegate: Text {
                                    text: "*34 PSI"
                                    color: "#8aa1b1"
                                    font.pixelSize: 13
                                    x: parent.width * modelData.xF
                                    y: parent.height * modelData.yF
                                }
                            }
                        }

                        Text {
                            text: "Warmup"
                            color: "#4da6ff"
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Column {
                        spacing: 25
                        width: parent.width - 185
                        anchors.verticalCenter: parent.verticalCenter

                        IconStatusRow {
                            iconSource: "assets/Icons/oil-temp.png"
                            value: "54 °F"
                            level: 0.54
                        }

                        IconStatusRow {
                            iconSource: "assets/Icons/battery.png"
                            value: "24 V"
                            level: 0.5
                        }

                        IconStatusRow {
                            iconSource: "assets/Icons/coolant.png"
                            value: "1.8 bar"
                            level: 0.36
                        }

                        IconStatusRow {
                            iconSource: "assets/Indicators/fuel.svg"
                            value: "850 mi"
                            level: 0.8
                        }
                    }
                }
            }
        }

        //Indicators
        Row {
            spacing: 75
            anchors.top: statusPanel.bottom
            anchors.topMargin: 30

            anchors.right: statusPanel.right
            anchors.rightMargin: 5

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

        Text {
            id: odometer
            text: "<font color='#F4C430'>ODO</font> 12,450 mi"
            color: "white"
            font.pixelSize: 28
            opacity: 0.85
            font.weight: Font.Light

            anchors.top: rpmGauge.bottom
            anchors.topMargin: -10
            anchors.horizontalCenter: parent.horizontalCenter

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: "black"
                radius: 4
                samples: 8
            }
        }

        //Lane assist
        Item {
            id: laneAssist
            width: 245
            height: 60

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: odometer.bottom
            anchors.topMargin: 10

            // Background pill
            Rectangle {
                id: backgroundPill
                anchors.fill: parent
                opacity: 0.85
                topLeftRadius: 25
                topRightRadius: 25
                bottomLeftRadius: 0
                bottomRightRadius: 0

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#3a5a7d"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#213e5e"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#12253a"
                    }
                }

                border.color: "#6a8fb3"
                border.width: 1

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#000000"
                    shadowBlur: 0.2
                    shadowVerticalOffset: 2
                }
            }

            Image {
                id: laneIcon
                source: "assets/Icons/lane-assist.png"
                anchors.centerIn: parent
                width: 65
                height: 65
                fillMode: Image.PreserveAspectFit
            }
        }
    }
}
