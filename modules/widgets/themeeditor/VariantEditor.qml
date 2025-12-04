pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.config

StyledRect {
    id: root

    required property string variantId

    signal updateVariant(string property, var value)
    signal close

    variant: "pane"

    // Get the Config object for this variant (reads directly from Config)
    readonly property var variantConfig: {
        switch (variantId) {
        case "bg":
            return Config.theme.srBg;
        case "internalbg":
            return Config.theme.srInternalBg;
        case "pane":
            return Config.theme.srPane;
        case "common":
            return Config.theme.srCommon;
        case "focus":
            return Config.theme.srFocus;
        case "primary":
            return Config.theme.srPrimary;
        case "primaryfocus":
            return Config.theme.srPrimaryFocus;
        case "overprimary":
            return Config.theme.srOverPrimary;
        case "secondary":
            return Config.theme.srSecondary;
        case "secondaryfocus":
            return Config.theme.srSecondaryFocus;
        case "oversecondary":
            return Config.theme.srOverSecondary;
        case "tertiary":
            return Config.theme.srTertiary;
        case "tertiaryfocus":
            return Config.theme.srTertiaryFocus;
        case "overtertiary":
            return Config.theme.srOverTertiary;
        case "error":
            return Config.theme.srError;
        case "errorfocus":
            return Config.theme.srErrorFocus;
        case "overerror":
            return Config.theme.srOverError;
        default:
            return null;
        }
    }

    readonly property string variantDisplayName: {
        switch (variantId) {
        case "bg":
            return "Background";
        case "internalbg":
            return "Internal Background";
        case "pane":
            return "Pane";
        case "common":
            return "Common";
        case "focus":
            return "Focus";
        case "primary":
            return "Primary";
        case "primaryfocus":
            return "Primary Focus";
        case "overprimary":
            return "Over Primary";
        case "secondary":
            return "Secondary";
        case "secondaryfocus":
            return "Secondary Focus";
        case "oversecondary":
            return "Over Secondary";
        case "tertiary":
            return "Tertiary";
        case "tertiaryfocus":
            return "Tertiary Focus";
        case "overtertiary":
            return "Over Tertiary";
        case "error":
            return "Error";
        case "errorfocus":
            return "Error Focus";
        case "overerror":
            return "Over Error";
        default:
            return "Unknown";
        }
    }

    // List of available color names from Colors.qml
    readonly property var colorNames: ["background", "surface", "surfaceBright", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "surfaceContainerLow", "surfaceContainerLowest", "surfaceDim", "surfaceTint", "surfaceVariant", "primary", "primaryContainer", "primaryFixed", "primaryFixedDim", "secondary", "secondaryContainer", "secondaryFixed", "secondaryFixedDim", "tertiary", "tertiaryContainer", "tertiaryFixed", "tertiaryFixedDim", "error", "errorContainer", "overBackground", "overSurface", "overSurfaceVariant", "overPrimary", "overPrimaryContainer", "overPrimaryFixed", "overPrimaryFixedVariant", "overSecondary", "overSecondaryContainer", "overSecondaryFixed", "overSecondaryFixedVariant", "overTertiary", "overTertiaryContainer", "overTertiaryFixed", "overTertiaryFixedVariant", "overError", "overErrorContainer", "outline", "outlineVariant", "inversePrimary", "inverseSurface", "inverseOnSurface", "shadow", "scrim", "blue", "blueContainer", "overBlue", "overBlueContainer", "cyan", "cyanContainer", "overCyan", "overCyanContainer", "green", "greenContainer", "overGreen", "overGreenContainer", "magenta", "magentaContainer", "overMagenta", "overMagentaContainer", "red", "redContainer", "overRed", "overRedContainer", "yellow", "yellowContainer", "overYellow", "overYellowContainer", "white", "whiteContainer", "overWhite", "overWhiteContainer"]

    // Helper to update a property - updates Config directly
    function updateProp(prop, value) {
        if (variantConfig) {
            variantConfig[prop] = value;
            root.updateVariant(prop, value);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12



        // 3-column layout
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            enabled: root.variantConfig !== null

            // === LEFT COLUMN: Type + Opacity ===
            ColumnLayout {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                spacing: 12

                // Gradient Type Section (vertical)
                Text {
                    text: "Gradient Type"
                    font.family: Styling.defaultFont
                    font.pixelSize: Config.theme.fontSize
                    font.bold: true
                    color: Colors.primary
                }

                Repeater {
                    model: ["linear", "radial", "halftone"]

                    delegate: Button {
                        id: typeButton
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        readonly property bool isSelected: root.variantConfig && root.variantConfig.gradientType === modelData

                        background: StyledRect {
                            variant: typeButton.isSelected ? "primary" : (typeButton.hovered ? "focus" : "common")
                        }

                        contentItem: Text {
                            text: typeButton.modelData.charAt(0).toUpperCase() + typeButton.modelData.slice(1)
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            color: typeButton.isSelected ? Colors.overPrimary : Colors.overBackground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: root.updateProp("gradientType", modelData)
                    }
                }

                Item {
                    Layout.preferredHeight: 20
                }

                // Opacity Section
                Text {
                    text: "Opacity"
                    font.family: Styling.defaultFont
                    font.pixelSize: Config.theme.fontSize
                    font.bold: true
                    color: Colors.primary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    StyledSlider {
                        id: opacitySlider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        value: root.variantConfig ? root.variantConfig.opacity : 1.0
                        vertical: false
                        resizeParent: false
                        scroll: false
                        tooltip: true
                        tooltipText: root.variantConfig ? (root.variantConfig.opacity * 100).toFixed(0) + "%" : "100%"
                        onValueChanged: {
                            if (root.variantConfig && Math.abs(value - root.variantConfig.opacity) > 0.001) {
                                root.updateProp("opacity", value);
                            }
                        }
                    }

                    Text {
                        text: root.variantConfig ? (root.variantConfig.opacity * 100).toFixed(0) + "%" : "100%"
                        font.family: Styling.defaultFont
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.overBackground
                        Layout.preferredWidth: 45
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            // === CENTER COLUMN: Options ===
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    // Item Color Section
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Item Color (Icons/Text)"

                        background: StyledRect {
                            variant: "common"
                        }

                        label: Text {
                            text: parent.title
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.primary
                            leftPadding: 10
                        }

                        ColorSelector {
                            anchors.fill: parent
                            colorNames: root.colorNames
                            currentValue: root.variantConfig ? root.variantConfig.itemColor : ""
                            onColorChanged: newColor => root.updateProp("itemColor", newColor)
                        }
                    }

                    // Border Section
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Border"

                        background: StyledRect {
                            variant: "common"
                        }

                        label: Text {
                            text: parent.title
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.primary
                            leftPadding: 10
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 14

                            // Border width
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Width:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 70
                                }

                                StyledSlider {
                                    id: borderWidthSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    value: root.variantConfig ? root.variantConfig.border[1] / 16 : 0
                                    resizeParent: false
                                    scroll: false
                                    tooltip: true
                                    tooltipText: Math.round(value * 16) + "px"
                                    onValueChanged: {
                                        if (root.variantConfig) {
                                            const newWidth = Math.round(value * 16);
                                            if (newWidth !== root.variantConfig.border[1]) {
                                                root.updateProp("border", [root.variantConfig.border[0], newWidth]);
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: root.variantConfig ? root.variantConfig.border[1] + "px" : "0px"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            // Border color
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Color:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 70
                                }

                                ColorSelector {
                                    Layout.fillWidth: true
                                    colorNames: root.colorNames
                                    currentValue: root.variantConfig ? root.variantConfig.border[0] : ""
                                    onColorChanged: newColor => {
                                        if (!root.variantConfig)
                                            return;
                                        let border = [newColor, root.variantConfig.border[1]];
                                        root.updateProp("border", border);
                                    }
                                }
                            }
                        }
                    }

                    // Type-specific settings
                    GroupBox {
                        Layout.fillWidth: true
                        title: {
                            if (!root.variantConfig)
                                return "Type Settings";
                            switch (root.variantConfig.gradientType) {
                            case "linear":
                                return "Linear Settings";
                            case "radial":
                                return "Radial Settings";
                            case "halftone":
                                return "Halftone Settings";
                            default:
                                return "Type Settings";
                            }
                        }
                        visible: root.variantConfig !== null

                        background: StyledRect {
                            variant: "common"
                        }

                        label: Text {
                            text: parent.title
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.primary
                            leftPadding: 10
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 14

                            // Angle (for linear)
                            RowLayout {
                                visible: root.variantConfig && root.variantConfig.gradientType === "linear"
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Angle:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 70
                                }

                                StyledSlider {
                                    id: angleSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    value: root.variantConfig ? root.variantConfig.gradientAngle / 360 : 0
                                    resizeParent: false
                                    scroll: false
                                    tooltip: true
                                    tooltipText: Math.round(value * 360) + "°"
                                    onValueChanged: {
                                        if (root.variantConfig) {
                                            const newAngle = Math.round(value * 360);
                                            if (newAngle !== root.variantConfig.gradientAngle) {
                                                root.updateProp("gradientAngle", newAngle);
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: root.variantConfig ? root.variantConfig.gradientAngle + "°" : "0°"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 45
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            // Center X/Y (for radial)
                            RowLayout {
                                visible: root.variantConfig && root.variantConfig.gradientType === "radial"
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Center X:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 70
                                }

                                StyledSlider {
                                    id: centerXSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    value: root.variantConfig ? root.variantConfig.gradientCenterX : 0.5
                                    resizeParent: false
                                    scroll: false
                                    tooltip: true
                                    tooltipText: (value * 100).toFixed(0) + "%"
                                    onValueChanged: {
                                        if (root.variantConfig && Math.abs(value - root.variantConfig.gradientCenterX) > 0.001) {
                                            root.updateProp("gradientCenterX", value);
                                        }
                                    }
                                }

                                Text {
                                    text: root.variantConfig ? root.variantConfig.gradientCenterX.toFixed(2) : "0.50"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 45
                                }
                            }

                            RowLayout {
                                visible: root.variantConfig && root.variantConfig.gradientType === "radial"
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Center Y:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 70
                                }

                                StyledSlider {
                                    id: centerYSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    value: root.variantConfig ? root.variantConfig.gradientCenterY : 0.5
                                    resizeParent: false
                                    scroll: false
                                    tooltip: true
                                    tooltipText: (value * 100).toFixed(0) + "%"
                                    onValueChanged: {
                                        if (root.variantConfig && Math.abs(value - root.variantConfig.gradientCenterY) > 0.001) {
                                            root.updateProp("gradientCenterY", value);
                                        }
                                    }
                                }

                                Text {
                                    text: root.variantConfig ? root.variantConfig.gradientCenterY.toFixed(2) : "0.50"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 45
                                }
                            }

                            // === HALFTONE OPTIONS ===
                            // Angle
                            RowLayout {
                                visible: root.variantConfig && root.variantConfig.gradientType === "halftone"
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Angle:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 110
                                }

                                StyledSlider {
                                    id: halftoneAngleSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    value: root.variantConfig ? root.variantConfig.gradientAngle / 360 : 0
                                    resizeParent: false
                                    scroll: false
                                    tooltip: true
                                    tooltipText: Math.round(value * 360) + "°"
                                    onValueChanged: {
                                        if (root.variantConfig) {
                                            const newAngle = Math.round(value * 360);
                                            if (newAngle !== root.variantConfig.gradientAngle) {
                                                root.updateProp("gradientAngle", newAngle);
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: root.variantConfig ? root.variantConfig.gradientAngle + "°" : "0°"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 45
                                }
                            }

                            // Dot Min
                            RowLayout {
                                visible: root.variantConfig && root.variantConfig.gradientType === "halftone"
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Dot Min:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 110
                                }

                                StyledSlider {
                                    id: dotMinSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    value: root.variantConfig ? root.variantConfig.halftoneDotMin / 20 : 0.1
                                    resizeParent: false
                                    scroll: false
                                    tooltip: true
                                    tooltipText: (value * 20).toFixed(1)
                                    onValueChanged: {
                                        if (root.variantConfig) {
                                            const newVal = value * 20;
                                            if (Math.abs(newVal - root.variantConfig.halftoneDotMin) > 0.01) {
                                                root.updateProp("halftoneDotMin", newVal);
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: root.variantConfig ? root.variantConfig.halftoneDotMin.toFixed(1) : "2.0"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 45
                                }
                            }

                            // Dot Max
                            RowLayout {
                                visible: root.variantConfig && root.variantConfig.gradientType === "halftone"
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Dot Max:"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 110
                                }

                                StyledSlider {
                                    id: dotMaxSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    value: root.variantConfig ? root.variantConfig.halftoneDotMax / 20 : 0.4
                                    resizeParent: false
                                    scroll: false
                                    tooltip: true
                                    tooltipText: (value * 20).toFixed(1)
                                    onValueChanged: {
                                        if (root.variantConfig) {
                                            const newVal = value * 20;
                                            if (Math.abs(newVal - root.variantConfig.halftoneDotMax) > 0.01) {
                                                root.updateProp("halftoneDotMax", newVal);
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: root.variantConfig ? root.variantConfig.halftoneDotMax.toFixed(1) : "8.0"
                                    font.family: Styling.defaultFont
                                    font.pixelSize: Config.theme.fontSize
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 45
                                }
                            }
                        }
                    }

                    // Spacer at the bottom
                    Item {
                        Layout.preferredHeight: 20
                    }
                }
            }

            // === RIGHT COLUMN: Gradient Stops / Halftone Options ===
            // Gradient Stops (Linear/Radial)
            GradientStopsEditor {
                Layout.preferredWidth: 350
                Layout.fillHeight: true
                colorNames: root.colorNames
                stops: root.variantConfig ? root.variantConfig.gradient : []
                variantId: root.variantId
                visible: root.variantConfig && root.variantConfig.gradientType !== "halftone"
                onUpdateStops: newStops => root.updateProp("gradient", newStops)
            }

            // Halftone Options
            GroupBox {
                Layout.fillHeight: true
                Layout.minimumWidth: 350
                Layout.maximumWidth: 350
                visible: root.variantConfig && root.variantConfig.gradientType === "halftone"
                title: "Halftone Options"

                background: StyledRect {
                    variant: "common"
                }

                label: Text {
                    text: parent.title
                    font.family: Styling.defaultFont
                    font.pixelSize: Config.theme.fontSize
                    font.bold: true
                    color: Colors.primary
                    leftPadding: 10
                }

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true

                    ColumnLayout {
                        width: 330
                        spacing: 14

                        // Dot Color
                        Text {
                            text: "Dot Color"
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.primary
                        }

                        ColorSelector {
                            Layout.fillWidth: true
                            colorNames: root.colorNames
                            currentValue: root.variantConfig ? root.variantConfig.halftoneDotColor : ""
                            onColorChanged: newColor => root.updateProp("halftoneDotColor", newColor)
                        }

                        // BG Color
                        Text {
                            text: "Background Color"
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.primary
                        }

                        ColorSelector {
                            Layout.fillWidth: true
                            colorNames: root.colorNames
                            currentValue: root.variantConfig ? root.variantConfig.halftoneBackgroundColor : ""
                            onColorChanged: newColor => root.updateProp("halftoneBackgroundColor", newColor)
                        }

                        // Start
                        Text {
                            text: "Start"
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.primary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            StyledSlider {
                                id: halftoneStartSliderRight
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                value: root.variantConfig ? root.variantConfig.halftoneStart : 0
                                resizeParent: false
                                scroll: false
                                tooltip: true
                                tooltipText: (value * 100).toFixed(0) + "%"
                                onValueChanged: {
                                    if (root.variantConfig && Math.abs(value - root.variantConfig.halftoneStart) > 0.001) {
                                        root.updateProp("halftoneStart", value);
                                    }
                                }
                            }

                            Text {
                                text: root.variantConfig ? root.variantConfig.halftoneStart.toFixed(2) : "0.00"
                                font.family: Styling.defaultFont
                                font.pixelSize: Config.theme.fontSize
                                color: Colors.overBackground
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        // End
                        Text {
                            text: "End"
                            font.family: Styling.defaultFont
                            font.pixelSize: Config.theme.fontSize
                            font.bold: true
                            color: Colors.primary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            StyledSlider {
                                id: halftoneEndSliderRight
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                value: root.variantConfig ? root.variantConfig.halftoneEnd : 1
                                resizeParent: false
                                scroll: false
                                tooltip: true
                                tooltipText: (value * 100).toFixed(0) + "%"
                                onValueChanged: {
                                    if (root.variantConfig && Math.abs(value - root.variantConfig.halftoneEnd) > 0.001) {
                                        root.updateProp("halftoneEnd", value);
                                    }
                                }
                            }

                            Text {
                                text: root.variantConfig ? root.variantConfig.halftoneEnd.toFixed(2) : "1.00"
                                font.family: Styling.defaultFont
                                font.pixelSize: Config.theme.fontSize
                                color: Colors.overBackground
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Item { Layout.preferredHeight: 20 }
                    }
                }
            }
        }
    }
}
