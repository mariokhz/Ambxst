import QtQuick
import Quickshell.Widgets
import qs.modules.theme
import qs.config
import qs.modules.components

Rectangle {
    radius: Config.roundness
    border.color: Colors[Config.theme.borderColor] || Colors.surfaceBright
    border.width: Config.theme.borderSize

    gradient: Gradient {
        orientation: Config.theme.bgOrientation === "horizontal" ? Gradient.Horizontal : Gradient.Vertical

        GradientStop {
            property var stopData: Config.theme.bgColor[0] || ["background", 0.0]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }

        GradientStop {
            property var stopData: Config.theme.bgColor[1] || Config.theme.bgColor[Config.theme.bgColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }

        GradientStop {
            property var stopData: Config.theme.bgColor[2] || Config.theme.bgColor[Config.theme.bgColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }

        GradientStop {
            property var stopData: Config.theme.bgColor[3] || Config.theme.bgColor[Config.theme.bgColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }

        GradientStop {
            property var stopData: Config.theme.bgColor[4] || Config.theme.bgColor[Config.theme.bgColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }
    }

    layer.enabled: true
    layer.effect: Shadow {}
}
