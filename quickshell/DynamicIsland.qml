// Save this to: ~/.config/frosted-island/DynamicIsland.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris

Rectangle {
    id: island

    // --- Color Palette ---
    property color colBase: "#06141B"
    property color colPanel: Qt.rgba(0x11/255, 0x21/255, 0x2D/255, 0.65) // Frosted glass with 65% opacity
    property color colBorder: "#4A5C6A"
    property color colText: "#CCD0CF"
    property color colAccent: "#20e3b2" // Custom glowing teal highlights

    // --- Kinetic Pill Dimension Limits ---
    property int baseWidth: 240
    property int baseHeight: 38
    
    width: baseWidth
    height: baseHeight
    radius: height / 2 // Morphing boundaries keep the pill perfectly rounded
    
    color: colPanel
    border.color: colBorder
    border.width: 1

    // --- State Machine Layouts ---
    state: "idle"
    
    states: [
        State {
            name: "idle"
            PropertyChanges { target: island; width: 240; height: 38; radius: 19 }
        },
        State {
            name: "media"
            PropertyChanges { target: island; width: 420; height: 38; radius: 19 }
        },
        State {
            name: "weather"
            PropertyChanges { target: island; width: 320; height: 120; radius: 24 }
        },
        State {
            name: "launcher"
            PropertyChanges { target: island; width: 600; height: 300; radius: 24 }
        },
        State {
            name: "calculator"
            PropertyChanges { target: island; width: 320; height: 280; radius: 24 }
        }
    ]

    // --- Spring Kinetics Fluid Transitions ---
    transitions: Transition {
        NumberAnimation {
            properties: "width,height,radius"
            duration: 480
            easing.type: Easing.OutExpo
        }
    }

    // --- Backend Socket IPC ---
    IpcHandler {
        target: "island"
        function setState(newState: string): void {
            island.state = newState
        }
    }

    // --- Live Weather Stream (wttr.in) ---
    property string weatherText: "Fetching..."
    Process {
        id: weatherProc
        command: ["curl", "-s", "wttr.in/Fedora?format=%c+%t+%C"] 
        stdout: StdioCollector {
            // onFinished: function(data) {
               // if (data.trim().length > 0) {
                    weatherText = data.trim()
                }// else {
                    weatherText = "Weather offline"
                }
            }
        }
    }
    
    Timer {
        interval: 1800000 // Refresh weather hourly
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.exec()
    }

    // --- Built-in MPRIS Media Services ---
    property var activePlayer: Mpris.players.count > 0 ? Mpris.players.get(0) : null
    property string nowPlayingText: {
        if (!activePlayer) return "No active media track"
        return activePlayer.trackTitle + " - " + activePlayer.trackArtists.join(", ")
    }

    // --- Sub-View Layout Panels ---
    StackLayout {
        anchors.fill: parent
        anchors.margins: 12
        currentIndex: {
            if (island.state === "idle") return 0;
            if (island.state === "media") return 1;
            if (island.state === "weather") return 2;
            if (island.state === "launcher") return 3;
            if (island.state === "calculator") return 4;
            return 0;
        }

        // View 0: Clock Widget (Idle Pill Mode)
        RowLayout {
            spacing: 8
            Rectangle {
                width: 6; height: 6; radius: 3
                color: colAccent
                opacity: 0.8
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: Qt.formatDateTime(new Date(), "hh:mm A ddd")
                color: colText
                font.family: "Space Grotesk"
                font.pixelSize: 13
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // View 1: Media Player (Horizontal Control Pill)
        RowLayout {
            spacing: 12
            Rectangle { 
                width: 22; height: 18; radius: 4
                color: colAccent
                Layout.alignment: Qt.AlignVCenter
                Text { text: "🔊"; anchors.centerIn: parent; font.pixelSize: 9 }
            }
            Text { 
                text: nowPlayingText
                color: colText
                font.family: "Space Grotesk"
                font.pixelSize: 12
                Layout.fillWidth: true 
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "⏸"
                color: colText
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (activePlayer) activePlayer.togglePlayPause()
                }
            }
        }

        // View 2: Weather Expanded View
        ColumnLayout {
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Fedora Station"
                    color: colText
                    font.family: "Space Grotesk"
                    font.pixelSize: 16
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Refresh ⟳"
                    color: colAccent
                    font.family: "Space Grotesk"
                    font.pixelSize: 11
                    MouseArea {
                        anchors.fill: parent
                        onClicked: weatherProc.exec();
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: colBorder
                opacity: 0.3
            }
            RowLayout {
                spacing: 15
                Text {
                    text: weatherText
                    color: colText
                    font.family: "Space Grotesk"
                    font.pixelSize: 28
                    font.bold: true
                }
                ColumnLayout {
                    spacing: 2
                    Text { text: "Humidity: Live Map"; color: colText; opacity: 0.7; font.pixelSize: 11 }
                    Text { text: "Forecast: Local Station"; color: colText; opacity: 0.7; font.pixelSize: 11 }
                }
            }
        }

        // View 3: App Launcher Grid Portal
        ColumnLayout {
            spacing: 12
            RowLayout {
                Text { text: "Application Portal"; color: colText; font.bold: true; font.pixelSize: 14 }
                Item { Layout.fillWidth: true }
                Text { text: "[Esc] Close"; color: colText; opacity: 0.5; font.pixelSize: 11 }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: colBorder; opacity: 0.3 }
            
            GridLayout {
                columns: 4
                rowSpacing: 10
                columnSpacing: 15
                Layout.alignment: Qt.AlignHCenter
                
                Repeater {
                    model: [
                        { name: "Alacritty", icon: "💻", cmd: "alacritty" },
                        { name: "Nautilus", icon: "📁", cmd: "nautilus" },
                        { name: "Firefox", icon: "🌐", cmd: "firefox" },
                        { name: "Settings", icon: "⚙️", cmd: "alacritty -e $EDITOR ~/.config/niri/config.kdl" }
                    ]
                    
                    delegate: ColumnLayout {
                        spacing: 2
                        Rectangle {
                            width: 44; height: 44; radius: 10
                            color: colBorder
                            opacity: 0.2
                            border.color: colAccent
                            border.width: 1
                            Text {
                                text: modelData.icon
                                font.pixelSize: 22
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var proc = Qt.createQmlObject("import Quickshell.Io 1.0; Process { command: ['" + modelData.cmd + "'] }", island);
                                    proc.exec();
                                    island.state = "idle";
                                }
                            }
                        }
                        Text {
                            text: modelData.name
                            color: colText
                            font.pixelSize: 9
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // View 4: Embedded Calculator
        ColumnLayout {
            spacing: 8
            RowLayout {
                Text { text: "Quickshell Calculator"; color: colText; font.bold: true; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Text { text: "qalc Engine"; color: colAccent; font.pixelSize: 10 }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: colBase
                radius: 6
                border.color: colBorder
                border.width: 1
                
                TextInput {
                    id: calcInput
                    anchors.fill: parent
                    anchors.margins: 6
                    color: colText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    focus: island.state === "calculator"
                    onAccepted: calcProcess.exec()
                }
            }
            
            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                
                Text { id: calcResult; text: "Result = 0"; color: colText; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                
                Rectangle {
                    width: 60; height: 26; radius: 4
                    color: colAccent
                    Text { text: "Solve"; anchors.centerIn: parent; color: colBase; font.bold: true; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: calcProcess.exec()
                    }
                }
            }
            
            Process {
                id: calcProcess
                command: ["qalc", "-t", calcInput.text]
                stdout: StdioCollector {
                    onFinished: function(data) {
                        calcResult.text = "Result = " + data.trim()
                    }
                }
            }
        }
    }

    // Touch Reset back to basic quiet pill
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (island.state !== "idle") {
                island.state = "idle"
            }
        }
    }
}
