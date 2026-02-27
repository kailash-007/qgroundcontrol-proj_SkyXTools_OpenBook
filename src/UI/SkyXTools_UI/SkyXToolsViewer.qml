import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

Rectangle
{
    property var skyXTools: QGroundControl.skyxmanager

    width:  250
    height: 150
    color:  qgcPal.window
    radius: 10
    border.color: qgcPal.text
    border.width: 1

    Column {
        anchors.centerIn: parent
        spacing: 10

        QGCLabel {
            text: "SKYX SYSTEM STATUS"
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: 20
            QGCLabel { text: "Battery:" }
            QGCLabel {
                text: skyXTools.batteryVoltage.toFixed(1) + "%"
                color: skyXTools.batteryVoltage < 20 ? "red" : qgcPal.text
            }
        }

        Row {
            spacing: 20
            QGCLabel { text: "Flights:" }
            QGCLabel { text: skyXTools.flightMode }
        }

        QGCLabel {
            text: skyXTools.statusText
            font.pointSize: ScreenTools.smallFontPointSize
            color: qgcPal.brandSecondary
        }
    }
}
