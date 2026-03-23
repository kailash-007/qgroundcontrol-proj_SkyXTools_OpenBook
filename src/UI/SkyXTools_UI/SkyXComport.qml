import QtQuick
import QtQuick.Controls
import QGroundControl
import QGroundControl.Controls

Popup
{
    id:               root
    width:            320
    height:           220
    modal:            true
    focus:            true
    closePolicy:      Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // qml variables

    property var    skyXTools: QGroundControl.skyxmanager
    property bool   connected: skyXTools.isConnected
    property bool previouslyConnected: false

    function refreshPortModel() {
        portCombo.currentIndex = -1        // ← reset FIRST before clearing
        baudCombo.currentIndex = -1        // ← reset baud too
        portModel.clear()                  // ← now safe to clear
        var ports = skyXTools.availablePorts()
        for (var i = 0; i < ports.length; i++) {
            portModel.append({ "name": ports[i] })
        }
        portCombo.currentIndex = portModel.count > 0 ? 0 : -1
        baudCombo.currentIndex = 0         // ← restore baud default
    }

    //Overall Background
    background: Rectangle
    {
        color:        "#1A1E28"
        radius:       12
        border.color: "#252B3A"
        border.width: 1
    }

    // qml local list of available ports
    ListModel { id: portModel }

    // When the btn is clicked and opened, Auto fill ports
    onOpened:
    {
        refreshPortModel()
    }

    onConnectedChanged:
    {
        if (!connected)
        {
            console.log("Disconnected — refreshing ports")
            refreshPortModel()
        }
    }

    // Updates port in UI when signal is received from SkyXManager.cpp
    Connections
    {
        target: skyXTools

        function onPortsChanged() {
            console.log("Disconnect Signal emmitted")
            refreshPortModel()
        }

        // Connection state changed — handle auto disconnect
        function onDataChanged() {
            if (!skyXTools.isConnected && previouslyConnected) {
                console.log("Auto disconnected — port removed")
            }
            previouslyConnected = skyXTools.isConnected
        }
    }

    Column
    {
        anchors.fill:    parent
        anchors.margins: 20
        spacing:         16

        // PopUp Title
        QGCLabel
        {
            text:               "SERIAL CONNECTION"
            font.bold:          true
            font.pointSize:     ScreenTools.smallFontPointSize
            font.letterSpacing: 2
            color:              "#00E5A0"
        }

        // COM Port Row Layout
        Row
        {
            width:   parent.width
            spacing: 10

            QGCLabel
            {
                text:           "PORT"
                font.pointSize: ScreenTools.smallFontPointSize - 1
                color:          "#8B92A8"
                width:          50
                anchors.verticalCenter: parent.verticalCenter
            }


            /*
                Row total width = parent.width

                Items inside Row:
                  Label        = 50px
                  spacing      = 10px  (between label and combobox)
                  ComboBox     = ?      ← we calculate this
                  spacing      = 10px  (between combobox and refresh)
                  RefreshBtn   = 32px  (but you wrote 38?)

                Total spacing = 10 + 10 = 20
            */
            // Port ComboBox
            Rectangle
            {
                width:  parent.width - 50 - 38 - 20
                height: 32
                color:  "#0D0F15"
                radius: 6
                border.color: "#252B3A"
                border.width: 1

                QGCComboBox
                {
                    id:           portCombo
                    anchors.fill: parent
                    model:        portModel
                    textRole:     "name"

                    background: Rectangle
                    {
                        color:        "#0A0C12"    // ← slightly darker than parent (#0D0F15)
                        radius:       6            // ← round edges! ✅
                        border.color: "#252B3A"
                        border.width: 1
                    }

                    contentItem: QGCLabel
                    {
                        text:           portCombo.count > 0 ? portCombo.displayText : "No ports"
                        font.pointSize: ScreenTools.smallFontPointSize
                        color:          "#E8ECF4"
                        verticalAlignment:   Text.AlignVCenter  // ← vertically centered
                        horizontalAlignment: Text.AlignLeft     // ← left aligned
                        anchors.centerIn : parent
                    }
                }
            }

            // Refresh button
            Rectangle
            {
                width:  38
                height: 38
                radius: 6
                color:  "#0D0F15"
                border.color: "#252B3A"
                border.width: 1

                QGCLabel
                {
                    text:            "↺"
                    font.pointSize:  ScreenTools.mediumFontPointSize
                    color:           "#00E5A0"
                    anchors.centerIn: parent
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked:    skyXTools.refreshPorts()  // ← C++ call
                }
            }
        }

        // Baudrate Layout
        Row
        {
            width:   parent.width
            spacing: 10

            QGCLabel
            {
                text:           "BAUD"
                font.pointSize: ScreenTools.smallFontPointSize - 1
                color:          "#8B92A8"
                width:          50
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle
            {
                width:  parent.width - 50 - 38 - 20
                height: 32
                color:  "#0D0F15"
                radius: 6
                border.color: "#252B3A"
                border.width: 1

                QGCComboBox
                {
                    id:           baudCombo
                    anchors.fill: parent
                    model:        ["9600", "57600", "115200"]
                    currentIndex: 0

                    background: Rectangle
                    {
                        color:        "#0A0C12"
                        radius:       ScreenTools.defaultBorderRadius
                        border.color: "#252B3A"
                        border.width: 1
                    }

                    contentItem: QGCLabel
                    {
                        text:           baudCombo.displayText
                        font.pointSize: ScreenTools.smallFontPointSize
                        color:          "#E8ECF4"
                        verticalAlignment:   Text.AlignVCenter  // ← vertically centered
                        horizontalAlignment: Text.AlignLeft     // ← left aligned
                        anchors.centerIn: parent
                    }
                }
            }

            // Spacer
            Rectangle
            {
                width:  38
                height: 38
                radius: 6
                color:  "transparent"
            }
        }

        // Connect / Disconnect Button
        Rectangle
        {
            width:   parent.width
            height:  36
            radius:  8
            color:   connected ? "#FF5C5C" : "#00E5A0"

            QGCLabel
            {
                text:            connected ? "DISCONNECT" : "CONNECT"
                font.bold:       true
                font.pointSize:  ScreenTools.smallFontPointSize
                color:           "#12151C"
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked:
                {
                    if (connected)
                    {
                        portCombo.currentIndex = -1        // ← reset index first
                        portModel.clear()                  // ← clear model
                        skyXTools.disconnectSerial()       // ← then disconnect
                        root.close()
                        return
                    }

                    if (portCombo.count === 0) {
                        console.log("No ports available")
                        return
                    }

                    if (portCombo.currentIndex < 0 ||
                        portCombo.currentIndex >= portModel.count) {
                        console.log("Invalid port index:", portCombo.currentIndex)
                        return
                    }

                    if (baudCombo.currentIndex < 0) {
                        console.log("Invalid baud index")
                        return
                    }

                    var selectedPort = portModel.get(portCombo.currentIndex).name
                    var selectedBaud = parseInt(baudCombo.displayText)

                    if (isNaN(selectedBaud) || selectedBaud <= 0) {
                        console.log("Invalid baud rate:", baudCombo.displayText)
                        return
                    }

                    console.log("Connecting to:", selectedPort, "at", selectedBaud)
                    skyXTools.connectSerial(selectedPort, selectedBaud)
                    root.close()
                }
            }
        }
    }
}
