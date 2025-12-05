pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.config

Item {
    id: root

    property string selectedVariant: "bg"  // Start with srBg selected

    signal updateVariant(string variantId, string property, var value)

    readonly property var allVariants: [
        { id: "bg", label: "Background" },
        { id: "internalbg", label: "Internal BG" },
        { id: "pane", label: "Pane" },
        { id: "common", label: "Common" },
        { id: "focus", label: "Focus" },
        { id: "primary", label: "Primary" },
        { id: "primaryfocus", label: "Primary Focus" },
        { id: "overprimary", label: "Over Primary" },
        { id: "secondary", label: "Secondary" },
        { id: "secondaryfocus", label: "Secondary Focus" },
        { id: "oversecondary", label: "Over Secondary" },
        { id: "tertiary", label: "Tertiary" },
        { id: "tertiaryfocus", label: "Tertiary Focus" },
        { id: "overtertiary", label: "Over Tertiary" },
        { id: "error", label: "Error" },
        { id: "errorfocus", label: "Error Focus" },
        { id: "overerror", label: "Over Error" }
    ]

    // Helper function to get variant label by id
    function getVariantLabel(variantId) {
        for (var i = 0; i < allVariants.length; i++) {
            if (allVariants[i].id === variantId) {
                return allVariants[i].label;
            }
        }
        return variantId;
    }

    StyledRect {
        anchors.fill: parent
        variant: "pane"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Variant selector row: Preview + Flow tags
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: variantsFlow.implicitHeight
                spacing: 12

                // Selected variant preview
                StyledRect {
                    id: selectedPreview
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignTop
                    variant: root.selectedVariant
                    enableBorder: true

                    // Cube icon
                    Text {
                        anchors.centerIn: parent
                        text: Icons.cube
                        font.family: Icons.font
                        font.pixelSize: 24
                        color: selectedPreview.itemColor
                    }
                }

                // Flow layout with variant tags
                Flow {
                    id: variantsFlow
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 4

                    Repeater {
                        model: root.allVariants

                        delegate: StyledRect {
                            id: variantTag
                            required property var modelData
                            required property int index

                            property bool isSelected: root.selectedVariant === modelData.id
                            property bool isHovered: false

                            // Use the variant's own styling for the tag
                            variant: modelData.id

                            // Dynamic width based on content
                            width: tagContent.width + 24 + (isSelected ? checkIcon.width + 4 : 0)
                            height: 32
                            radius: isSelected ? Styling.radius(0) / 2 : Styling.radius(0)

                            Behavior on radius {
                                enabled: (Config.animDuration ?? 0) > 0
                                NumberAnimation {
                                    duration: (Config.animDuration ?? 0) / 2
                                    easing.type: Easing.OutQuart
                                }
                            }

                            Behavior on width {
                                enabled: (Config.animDuration ?? 0) > 0
                                NumberAnimation {
                                    duration: (Config.animDuration ?? 0) / 3
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 8

                                Row {
                                    anchors.centerIn: parent
                                    spacing: isSelected ? 4 : 0

                                    // Check icon with reveal animation
                                    Item {
                                        width: checkIcon.visible ? checkIcon.width : 0
                                        height: checkIcon.height
                                        clip: true

                                        Text {
                                            id: checkIcon
                                            text: Icons.accept
                                            font.family: Icons.font
                                            font.pixelSize: 16
                                            color: variantTag.itemColor
                                            visible: isSelected
                                            opacity: isSelected ? 1 : 0

                                            Behavior on opacity {
                                                enabled: (Config.animDuration ?? 0) > 0
                                                NumberAnimation {
                                                    duration: (Config.animDuration ?? 0) / 3
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        Behavior on width {
                                            enabled: (Config.animDuration ?? 0) > 0
                                            NumberAnimation {
                                                duration: (Config.animDuration ?? 0) / 3
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    Text {
                                        id: tagContent
                                        text: modelData.label
                                        font.family: Config.theme.font
                                        font.pixelSize: Config.theme.fontSize
                                        font.bold: true
                                        color: variantTag.itemColor

                                        Behavior on color {
                                            enabled: (Config.animDuration ?? 0) > 0
                                            ColorAnimation {
                                                duration: (Config.animDuration ?? 0) / 3
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }

                            // Hover overlay
                            Rectangle {
                                id: hoverOverlay
                                anchors.fill: parent
                                color: Colors.primary
                                radius: parent.radius
                                opacity: variantTag.isHovered ? 0.15 : 0

                                Behavior on opacity {
                                    enabled: (Config.animDuration ?? 0) > 0
                                    NumberAnimation {
                                        duration: (Config.animDuration ?? 0) / 2
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: variantTag.isHovered = true
                                onExited: variantTag.isHovered = false

                                onClicked: root.selectedVariant = modelData.id
                            }
                        }
                    }
                }
            }

            // Editor panel
            VariantEditor {
                Layout.fillWidth: true
                Layout.fillHeight: true
                variantId: root.selectedVariant
                onUpdateVariant: (property, value) => {
                    root.updateVariant(root.selectedVariant, property, value);
                }
                onClose: {} // No close button in new design
            }
        }
    }
}
