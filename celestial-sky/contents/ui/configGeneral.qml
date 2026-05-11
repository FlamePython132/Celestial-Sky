import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_userLat: latField.value
    property alias cfg_userLon: lonField.value
    property alias cfg_planetScale: scaleSlider.value
    property alias cfg_bgOpacity: opacitySlider.value

    SpinBox {
        id: latField
        Kirigami.FormData.label: "Latitude:"
        from: -90
        to: 90
        stepSize: 1
        value: 0
        property real realValue: value
    }

    SpinBox {
        id: lonField
        Kirigami.FormData.label: "Longitude:"
        from: -180
        to: 180
        stepSize: 1
        value: 0
        property real realValue: value
    }

    Slider {
        id: scaleSlider
        Kirigami.FormData.label: "Planet size:"
        from: 0.5
        to: 3.0
        stepSize: 0.1
        value: 1.0
    }

    Slider {
        id: opacitySlider
        Kirigami.FormData.label: "Background opacity:"
        from: 0.0
        to: 1.0
        stepSize: 0.05
        value: 1.0
    }
}
