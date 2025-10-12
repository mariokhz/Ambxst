import QtQuick
import QtQuick.Layouts
import qs.modules.bar
import qs.modules.services
import qs.modules.components

Item {
    Layout.preferredWidth: 100
    Layout.fillHeight: true

    BgRect {
        anchors.fill: parent
        StyledSlider {
            anchors.centerIn: parent
            width: parent.width - 8
            height: 4
            value: Audio.sink?.audio?.volume ?? 0

            onValueChanged: {
                if (Audio.sink?.audio) {
                    Audio.sink.audio.volume = value;
                }
            }
        }
    }
}
