import QtQuick
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

Rectangle {
    id:     root
    width:  size
    height: size
    radius: width / 2
    color:  qgcPal.window

    property real size:    ScreenTools.defaultFontPixelHeight * 10
    property real heading: 0    // ← bind to skyXTools.heading ✅

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // ── Rotating container ────────────────────────
    Item {
        id:           rotationParent
        anchors.fill: parent

        // ── Compass Dial (N S E W + ticks) ────────
        CompassDial {
            anchors.fill: parent    // ← reuse directly! ✅
        }

        // ── Red Arrow needle ──────────────────────
        CompassHeadingIndicator {
            compassSize: size
            heading:     root.heading   // ← skyXTools.heading ✅
            simplified:  false
        }
    }

    // ── Heading degrees label ─────────────────────
    QGCLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        y:                        size * 0.74
        text:                     root.heading.toFixed(0) + "°"
        horizontalAlignment:      Text.AlignHCenter
    }
}
