// Save this to: ~/.config/frosted-island/shell.qml
import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        id: topPanel
        anchors {
            top: true
            left: true
            right: true
        }
        // Plenty of heights so expanded configurations don't crop
        height: 440
        color: "transparent" // Panel window is invisible, the island rectangle manages visual layouts

        // Register custom Layer Shell Namespace for Niri compositor blurring rules
        WlrLayerShell.namespace: "frosted-island"
        WlrLayerShell.layer: WlrLayerShell.Top
        WlrLayerShell.keyboardFocus: WlrLayerShell.KeyboardFocusNone
        
        DynamicIsland {
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
