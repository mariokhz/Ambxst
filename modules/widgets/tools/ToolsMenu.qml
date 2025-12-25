import QtQuick
import qs.modules.components
import qs.modules.theme
import Quickshell.Io

ActionGrid {
    id: root

    signal itemSelected

    layout: "row"
    buttonSize: 48
    iconSize: 20
    spacing: 8

    actions: [
        {
            icon: Icons.regionScreenshot,
            tooltip: "Region Screenshot",
            command: ""
        },
        {
            icon: Icons.windowScreenshot,
            tooltip: "Window Screenshot",
            command: ""
        },
        {
            icon: Icons.fullScreenshot,
            tooltip: "Full Screenshot",
            command: ""
        },
        {
            icon: Icons.screenshots,
            tooltip: "Open Screenshots",
            command: ""
        },
        {
            icon: Icons.recordScreen,
            tooltip: "Record Screen",
            command: ""
        },
        {
            icon: Icons.recordings,
            tooltip: "Open Recordings",
            command: ""
        }
    ]

    onActionTriggered: action => {
        console.log("Tools action triggered:", action.tooltip);
        // Functionality pending
        root.itemSelected();
    }
}
