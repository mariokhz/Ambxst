pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    required property PwNode node
    property string icon: ""
    property bool isMainDevice: false

    implicitHeight: 56
    implicitWidth: parent?.width ?? 300

    PwObjectTracker {
        objects: [root.node]
    }

    readonly property bool isMuted: root.node?.audio?.muted ?? false
    readonly property real volume: root.node?.audio?.volume ?? 0
    property real lastSetVolume: volume

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // First row: Icon + Slider
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Mute button with icon
            Button {
                id: muteButton
                flat: true
                implicitWidth: 32
                implicitHeight: 40
                Layout.preferredWidth: 40
                Layout.maximumWidth: 40
                Layout.fillWidth: false

                background: StyledRect {
                    variant: muteButton.hovered ? "focus" : "common"
                    radius: Styling.radius(4)
                }

                contentItem: Item {
                    Image {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        mipmap: true
                        antialiasing: true
                        visible: source != "" && !root.isMuted && !root.isMainDevice
                        source: {
                            if (root.isMuted || root.isMainDevice) return "";
                            
                            let iconName;
                            // Try application icon name first
                            iconName = AppSearch.guessIcon(root.node?.properties["application.icon-name"] ?? "");
                            if (AppSearch.iconExists(iconName))
                                return Quickshell.iconPath(iconName);
                                
                            // Try node name as fallback
                            iconName = AppSearch.guessIcon(root.node?.properties["node.name"] ?? "");
                            if (AppSearch.iconExists(iconName))
                                return Quickshell.iconPath(iconName);

                            return "";
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !parent.children[0].visible
                        text: {
                            if (root.isMuted)
                                return Icons.speakerSlash;
                            if (root.icon)
                                return root.icon;
                            return Icons.speakerHigh;
                        }
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: root.isMuted ? Colors.error : Colors.overBackground

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }
                }

                onClicked: {
                    if (root.node?.audio) {
                        root.node.audio.muted = !root.node.audio.muted;
                    }
                }

                StyledToolTip {
                    visible: muteButton.hovered
                    tooltipText: root.isMuted ? "Unmute" : "Mute"
                }
            }

            // Volume slider
            StyledSlider {
                id: volumeSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                value: root.volume
                scroll: false
                progressColor: {
                    if (root.isMuted)
                        return Colors.outline;
                    if (Audio.protectionTriggered && root.isMainDevice)
                        return Colors.warning;
                    return Styling.srItem("overprimary");
                }

                onValueChanged: {
                    if (root.node?.audio && Math.abs(value - root.volume) > 0.001) {
                        Audio.setNodeVolume(root.node, value);
                    }
                }

                Behavior on progressColor {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: Config.animDuration / 2
                    }
                }
            }
        }

        // Second row: Name + Separator + Percentage
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Source name
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: {
                    if (root.isMainDevice) {
                        return Audio.friendlyDeviceName(root.node);
                    }
                    
                    const app = Audio.appNodeDisplayName(root.node);
                    const media = root.node.properties["media.name"];
                    // If media name exists and is different from app name, show both
                    return (media && media !== app) ? `${app} • ${media}` : app;
                }
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overSurfaceVariant
            }

            // Separator line
            Separator {
                Layout.fillWidth: true
            }

            // Protection indicator
            Text {
                visible: Audio.protectionTriggered && root.isMainDevice
                text: Icons.shieldCheck
                font.family: Icons.font
                font.pixelSize: 12
                color: Colors.warning

                StyledToolTip {
                    visible: parent.visible && protectionIndicatorMa.containsMouse
                    tooltipText: "Volume protection active"
                }

                MouseArea {
                    id: protectionIndicatorMa
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            // Percentage
            Text {
                text: `${Math.round(root.volume * 100)}%`
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overSurfaceVariant
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
