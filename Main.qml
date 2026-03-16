import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: root
    width: 1400
    height: 650
    color: "black"
    visible: true
    title: qsTr("Ferrari Cluster")

    property bool isNavMode: false
    property bool startupFinished: false

    Loader {
        id: layoutLoader
        anchors.fill: parent
        source: startupFinished ? (isNavMode ? "NavigationLayout.qml" : "StandardLayout.qml") : ""
        opacity: startupFinished ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 500
            }
        }

        onLoaded: {
            item.startupFinished = root.startupFinished;
        }
    }

    // --- STARTUP OVERLAY ---
    Item {
        id: startupOverlay
        anchors.fill: parent
        visible: !startupFinished

        Rectangle {
            anchors.fill: parent
            color: "black"
        }

        Image {
            id: logo
            source: "assets/qtLogo.png"   
            anchors.centerIn: parent
            width: 280
            fillMode: Image.PreserveAspectFit
            opacity: 0
            scale: 0.85
        }

        SequentialAnimation {
            id: startupAnimation
            running: false

            // Fade + Scale In
            ParallelAnimation {
                NumberAnimation {
                    target: logo
                    property: "opacity"
                    to: 1
                    duration: 1100
                }
                NumberAnimation {
                    target: logo
                    property: "scale"
                    to: 1.0
                    duration: 1100
                    easing.type: Easing.OutCubic
                }
            }

            PauseAnimation {
                duration: 300
            }

            // Fade Out Entire Overlay
            NumberAnimation {
                target: startupOverlay
                property: "opacity"
                to: 0
                duration: 300
            }

            ScriptAction {
                script: startupFinished = true
            }
        }
    }

    Rectangle {
        id: blackOverlay
        anchors.fill: parent
        color: "black"
        opacity: 0
        visible: opacity > 0
        z: 999
    }

    SequentialAnimation {
        id: layoutTransitionAnimation

        NumberAnimation {
            target: blackOverlay
            property: "opacity"
            to: 1
            duration: 350
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: isNavMode = !isNavMode
        }

        PauseAnimation {
            duration: 300
        }

        NumberAnimation {
            target: blackOverlay
            property: "opacity"
            to: 0
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (!startupFinished && !startupAnimation.running)
                startupAnimation.start()
        }
    }

    Shortcut {
        sequence: "N"
        onActivated: {
            if (startupFinished && !layoutTransitionAnimation.running)
                layoutTransitionAnimation.start()
        }
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (!startupFinished || layoutTransitionAnimation.running)
                return
            shutdownAnimation.start()
        }
    }

    NumberAnimation {
        id: shutdownAnimation
        target: blackOverlay
        property: "opacity"
        to: 1
        duration: 600
        easing.type: Easing.InCubic
        onStopped: startupFinished = false
    }
}
