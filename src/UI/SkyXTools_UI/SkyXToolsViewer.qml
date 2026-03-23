import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl.FlyView


Rectangle
{
    id: root
    property var skyXTools: QGroundControl.skyxmanager

    property bool mapFullScreen: false
    property bool followDrone: true

    // Derived state
    property bool connected:  skyXTools.isConnected
    property real battPct:    skyXTools.batteryPct
    property real battVol:    skyXTools.batteryVol
    property color accentOk:  "#00E5A0"
    property color accentWarn:"#FF5C5C"
    property color accentDim: "#3A3F4B"
    property color textPri:   connected ? "#E8ECF4" : "#55596A"
    property color textSec:   connected ? "#8B92A8" : "#3E424F"

    property bool previouslyConnected: false
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle


    Connections
    {
        target: skyXTools

        function onDataChanged()
        {
            // Debug
        }
    }

    width:  440
    height: parent.height
    color:  "#12151C"
    radius: 14

    // ── Thin top accent line ──────────────────────────
    Rectangle
    {
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: 2
        radius: 14
        gradient: Gradient
        {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: connected ? root.accentOk : root.accentDim }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    SkyXComport
    {
        id: comPortPopup
        anchors.centerIn: parent
    }

    // ── Header ────────────────────────────────────────
    Item
    {
        id: header
        anchors.top:         parent.top
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.topMargin:   2
        anchors.leftMargin:  18
        anchors.rightMargin: 18
        height: 48

        // Tool Bar

        QGCLabel {
            text:               "SKYX TOOLS"
            font.bold:          true
            font.pointSize:     ScreenTools.mediumFontPointSize
            font.letterSpacing: 2
            color:              root.textPri
            anchors.left:       parent.left
            anchors.verticalCenter: parent.verticalCenter


            HoverHandler { id: skyXTool_ToolBar_Hover }
            ToolTip.visible: skyXTool_ToolBar_Hover.hovered
            ToolTip.text:    "SkyX Tools telemetry panel"
            ToolTip.delay:   600
        }

        Row
        {
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // ── Map Toggle Button ──────────────────────
            Rectangle
            {
                width:  28
                height: 28
                radius: 6
                color:  mapFullScreen ? root.accentOk : "#1A1E28"
                border.color: mapFullScreen ? root.accentOk : "#252B3A"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                QGCLabel
                {
                    text:            "Btn"
                    font.pointSize:  ScreenTools.smallFontPointSize
                    color:           mapFullScreen ? "#12151C" : root.accentOk
                    anchors.centerIn: parent
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked:    root.mapFullScreen = !root.mapFullScreen
                }

                HoverHandler
                {
                   id: mapToggleHover
                }

                ToolTip.visible: mapToggleHover.hovered
                ToolTip.text:    mapFullScreen ? "Show status panels" : "Expand map"
                ToolTip.delay:   600
            }

            // Serial button indicator

            Rectangle
            {
                width:  90
                height: 28
                radius: 6
                color:       connected ? "#1A1E28" : "#00E5A0"
                border.color: connected ? "#FF5C5C" : "#00E5A0"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                QGCLabel
                {
                   text:            connected ? "DISCONNECT" : "CONNECT"
                   font.bold:       true
                   font.pointSize:  ScreenTools.smallFontPointSize - 1
                   color:           connected ? "#FF5C5C" : "#12151C"
                   anchors.centerIn: parent
                }

                MouseArea
                {
                   anchors.fill: parent
                   onClicked:    comPortPopup.open()
                }
            }

            // Round button indicator
            Rectangle
            {
                width: 8; height: 8; radius: 4
                color: connected ? root.accentOk : "#FF5C5C"
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity
                {
                    running:  connected
                    loops:    Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                }
            }

            QGCLabel
            {
                text:               connected ? "CONNECTED" : "DISCONNECTED"
                color:              connected ? root.accentOk : "#FF5C5C"
                font.pointSize:     ScreenTools.smallFontPointSize
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter

                HoverHandler { id: hovered }  // ← add this

                ToolTip.visible: hovered.hovered
                ToolTip.text:    connected ? "Vehicle link is active" : "No vehicle detected"
                ToolTip.delay:   600
            }

            QGCLabel
            {
                text:               connected
                                        ? "Serial  |  " + skyXTools.activePort + "  |  " + skyXTools.activeBaudrate
                                        : ""
                color:              "#8B92A8"
                font.pointSize:     ScreenTools.smallFontPointSize - 1
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
                visible:            connected
            }
        }
    }

    // Divider
    Rectangle {
        id: divider
        anchors.top:         header.bottom
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.leftMargin:  18
        anchors.rightMargin: 18
        height: 1
        color: "#1E2330"
    }

    // ── Cards ─────────────────────────────────────────
    Row {
        id: cards
        visible: !root.mapFullScreen   // ← hide when map fullscreen
        anchors.top:         divider.bottom
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.topMargin:   14
        anchors.leftMargin:  18
        anchors.rightMargin: 18
        spacing: 10

        // ── Battery Card ──────────────────────────────
        Rectangle {
            width:  (cards.width - 20) / 3
            height: 116
            color:  "#1A1E28"
            radius: 10
            border.color: connected ? "#252B3A" : "#1A1D24"
            border.width: 1
            opacity: connected ? 1.0 : 0.45

            HoverHandler { id: batteryCardHover }
            ToolTip.visible: batteryCardHover.hovered && connected
            ToolTip.text:    "Battery health percentage"
            ToolTip.delay:   600

            Column {
                anchors.centerIn: parent
                spacing: 8

                QGCLabel {
                    text:               "BATTERY"
                    font.bold:          true
                    font.pointSize:     ScreenTools.smallFontPointSize - 1
                    font.letterSpacing: 1.5
                    color:              root.textSec
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                QGCLabel {
                    text: connected ? battPct.toFixed(1) + "%" + "|" + battVol.toFixed(1) + "V": "--"
                    font.bold:      true
                    font.pointSize: ScreenTools.largeFontPointSize
                    color: !connected    ? root.textSec
                         : battPct < 20 ? root.accentWarn
                                        : root.accentOk
                    anchors.horizontalCenter: parent.horizontalCenter
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Rectangle {
                    width:  90
                    height: 5
                    radius: 3
                    color:  "#0D0F15"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width:  connected ? Math.max(6, parent.width * (battPct / 100)) : 0
                        height: parent.height
                        radius: 3
                        color:  battPct < 20 ? root.accentWarn : root.accentOk
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
            }

        }
//   Flight Card

    // ── Rectangle 1 — Flight Data ──────────────────────────────────────────────
    Rectangle {
        width:        (cards.width - 20) / 3
        height:       116
        color:        "#1A1E28"
        radius:       10
        border.color: connected ? "#252B3A" : "#1A1D24"
        border.width: 1
        opacity:      connected ? 1.0 : 0.45

        HoverHandler { id: flightCardHover }
        ToolTip.visible: flightCardHover.hovered && connected
        ToolTip.text:    "Flight information"
        ToolTip.delay:   600

        Column {
            anchors.centerIn: parent
            width:            140
            spacing:          6

            // ALT
            Row {
                width:   parent.width
                spacing: 12
                QGCLabel {
                    width:               60
                    text:                "ALT"
                    font.bold:           true
                    font.pointSize:      ScreenTools.smallFontPointSize - 1
                    font.letterSpacing:  1.2
                    color:               root.textSec
                    horizontalAlignment: Text.AlignLeft
                }
                QGCLabel {
                    text:           connected ? skyXTools.altitude.toFixed(1) + " m" : "--"
                    font.bold:      true
                    font.pointSize: ScreenTools.smallFontPointSize
                    color:          connected ? "#7EB8FF" : root.textSec
                }
            }

            // GND SPD
            Row {
                width:   parent.width
                spacing: 12
                QGCLabel {
                    width:               60
                    text:                "GND SPD"
                    font.bold:           true
                    font.pointSize:      ScreenTools.smallFontPointSize - 1
                    font.letterSpacing:  1.2
                    color:               root.textSec
                    horizontalAlignment: Text.AlignLeft
                }
                QGCLabel {
                    text:           connected ? skyXTools.groundSpeed.toFixed(1) + " m/s" : "--"
                    font.bold:      true
                    font.pointSize: ScreenTools.smallFontPointSize
                    color:          connected ? "#7EB8FF" : root.textSec
                }
            }

            // GPS
            Row {
                width:   parent.width
                spacing: 12
                QGCLabel {
                    width:               60
                    text:                "GPS"
                    font.bold:           true
                    font.pointSize:      ScreenTools.smallFontPointSize - 1
                    font.letterSpacing:  1.2
                    color:               root.textSec
                    horizontalAlignment: Text.AlignLeft
                }
                QGCLabel {
                    text: {
                        if (!connected) return "--"
                        switch (skyXTools.gpsFixType) {
                            case 0:
                            case 1:  return "No Fix"
                            case 2:  return "2D Fix"
                            case 3:  return "3D Fix"
                            case 4:
                            case 5:  return "RTK Float"
                            case 6:  return "RTK Fixed"
                            default: return "Unknown"
                        }
                    }
                    font.bold:      true
                    font.pointSize: ScreenTools.smallFontPointSize
                    color: {
                        if (!connected) return root.textSec
                        switch (skyXTools.gpsFixType) {
                            case 0:
                            case 1:  return "#FF5C5C"
                            case 2:  return "#FFB347"
                            case 3:  return root.accentOk
                            case 4:
                            case 5:  return "#FFB347"
                            case 6:  return root.accentOk
                            default: return root.textSec
                        }
                    }
                }
            }

            // STATUS
            Row {
                width:   parent.width
                spacing: 12
                QGCLabel {
                    width:               60
                    text:                "STATUS"
                    font.bold:           true
                    font.pointSize:      ScreenTools.smallFontPointSize - 1
                    font.letterSpacing:  1.2
                    color:               root.textSec
                    horizontalAlignment: Text.AlignLeft
                }
                QGCLabel {
                    text:           connected ? (skyXTools.isArmed ? "Armed" : "Disarmed") : "--"
                    font.bold:      true
                    font.pointSize: ScreenTools.smallFontPointSize
                    color:          connected ? (skyXTools.isArmed ? "#FF5C5C" : root.accentOk) : root.textSec
                }
            }
        }
    }

    // ── Rectangle 2 — Status Messages ──────────────────────────────────────────
    Rectangle {
        width:        (cards.width - 20) / 3
        height:       116
        color:        "#1A1E28"
        radius:       10
        border.color: connected ? "#252B3A" : "#1A1D24"
        border.width: 1
        opacity:      connected ? 1.0 : 0.45

        HoverHandler { id: statusCardHover }
        ToolTip.visible: statusCardHover.hovered && connected
        ToolTip.text:    "System status messages from vehicle"
        ToolTip.delay:   600

        Rectangle {
            anchors.fill:    parent
            anchors.margins: 4
            color:           "transparent"
            radius:          6
            border.color:    connected ? "#252B3A" : "#1A1D24"
            border.width:    1

            // Track mouse presence
            HoverHandler {
                id: scrollAreaHover
            }

            ScrollView {
                id:              statusScrollView
                anchors.fill:    parent
                anchors.margins: 4
                clip:            true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy:   ScrollBar.AsNeeded

                TextArea {
                    id:                  statusTextArea
                    width:               parent.width
                    text:                connected ? skyXTools.statusText : "No messages"
                    font.pointSize:      ScreenTools.smallFontPointSize
                    color:               connected ? root.accentOk : root.textSec
                    wrapMode:            TextArea.Wrap
                    readOnly:            true
                    background:          null
                    padding:             4
                    horizontalAlignment: TextArea.AlignLeft
                    Behavior on color { ColorAnimation { duration: 400 } }

                    // Only auto scroll when mouse is NOT hovering
                    onTextChanged: {
                        if (!scrollAreaHover.hovered) {
                            // Scroll to bottom where newest prepended text is at top
                            statusScrollView.ScrollBar.vertical.position = 0.0
                        }
                    }
                }
            }

            // CLR button
            Rectangle {
                anchors.bottom:  parent.bottom
                anchors.right:   parent.right
                anchors.margins: 4
                width:           36
                height:          14
                radius:          3
                color:           "#252B3A"
                visible:         connected

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               "CLR"
                    font.pointSize:     ScreenTools.smallFontPointSize - 2
                    font.bold:          true
                    font.letterSpacing: 1
                    color:              root.textSec
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    skyXTools.clearMessages()
                }
            }
        }
    }
//
    }

    // ── GPS Row ───────────────────────────────────────
    Rectangle {
        id: gpsRow
        visible: !root.mapFullScreen   // ← hide when map fullscreen
        anchors.top:         cards.bottom
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.topMargin:   10
        anchors.leftMargin:  18
        anchors.rightMargin: 18
        height: 52
        color:  "#1A1E28"
        radius: 10
        border.color: connected ? "#252B3A" : "#1A1D24"
        border.width: 1
        opacity: connected ? 1.0 : 0.45

        HoverHandler { id: gpsHover }
        ToolTip.visible: gpsHover.hovered && connected
        ToolTip.text:    "GPS coordinates from vehicle telemetry"
        ToolTip.delay:   600

        Row {
            anchors.centerIn: parent
            spacing: 32

            QGCLabel {
                text:               "GPS"
                font.bold:          true
                font.pointSize:     ScreenTools.smallFontPointSize - 1
                font.letterSpacing: 2
                color:              root.textSec
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1; height: 28
                color: "#1E2330"
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                QGCLabel {
                    text:           "LAT   " + (connected ? skyXTools.latitude.toFixed(6)  + "\u00B0" : "--")
                    font.pointSize: ScreenTools.smallFontPointSize
                    color:          root.textPri
                    font.family:    "Courier New"
                }
                QGCLabel {
                    text:           "LON  " + (connected ? skyXTools.longitude.toFixed(6) + "\u00B0" : "--")
                    font.pointSize: ScreenTools.smallFontPointSize
                    color:          root.textPri
                    font.family:    "Courier New"
                }
            }
        }
    }

    // ── Map Section ───────────────────────────────────
    Rectangle {
        id:     mapSection
        anchors.top: root.mapFullScreen ? header.bottom : gpsRow.bottom
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.topMargin:   10
        anchors.leftMargin:  18
        anchors.rightMargin: 18
        anchors.bottom:      parent.bottom
        anchors.bottomMargin: 20
        color:  "#0D0F15"
        radius: 10
        clip:   true       // clips map inside rounded corners
        border.color: connected ? "#252B3A" : "#1A1D24"
        border.width: 1

        // ── FlightMap ─────────────────────────────────
        FlightMap
        {
            id:           miniMap
            anchors.fill: parent
            mapName:     "FlightDisplayView"
            opacity:      connected ? 1.0 : 0.0 // ← hide map completely when disconnected


            // center on drone position — auto updates when lat/lon changes!
            center: followDrone ? QtPositioning.coordinate(
                skyXTools.latitude  ? skyXTools.latitude  : 28.6139,
                skyXTools.longitude ? skyXTools.longitude : 77.2088
            ) : miniMap.center

            onMapReadyChanged: {
                console.log("mapReady:", mapReady)
                console.log("supportedMapTypes:", supportedMapTypes.length)
                console.log("activeMapType:", activeMapType.name)
            }

            MouseArea
            {
                MouseArea
                {
                    anchors.fill: parent
                    propagateComposedEvents: true    // ← allow map to receive events too

                    // Only trigger popup on click, not on drag/pan
                    property bool isDragging: false
                    property real pressX: 0
                    property real pressY: 0

                    onPressed: (mouse) => {
                        pressX    = mouse.x
                        pressY    = mouse.y
                        isDragging = false
                    }

                    onPositionChanged: (mouse) => {
                        // If moved more than 5px consider it a drag/pan
                        if (Math.abs(mouse.x - pressX) > 5 || Math.abs(mouse.y - pressY) > 5) {
                            isDragging = true
                        }
                        mouse.accepted = false    // ← pass drag events to map
                    }

                    onClicked: (mouse) => {
                        // Only open popup if it was a real click not a pan
                        if (!isDragging) {
                            var coord = miniMap.toCoordinate(Qt.point(mouse.x, mouse.y))
                            latLonPopup.clickLat = coord.latitude
                            latLonPopup.clickLon = coord.longitude
                            latLonPopup.clickX   = mouse.x
                            latLonPopup.clickY   = mouse.y
                            console.log("Map clicked:", latLonPopup.clickLat, latLonPopup.clickLon)
                            latLonPopup.open()
                        }
                        mouse.accepted = false    // ← pass click to map too
                    }
                }
            }

            // street level zoom
            zoomLevel: 17

            // ── Drone Marker ──────────────────────────
            MapQuickItem
            {
                id:           droneMarker
                coordinate:   QtPositioning.coordinate(
                                  skyXTools.latitude  ? skyXTools.latitude  : 28.6139,
                                  skyXTools.longitude ? skyXTools.longitude : 77.2088
                              )
                // anchor point = center of icon
                visible:       connected

                sourceItem: Item
                {
                    width:  36
                    height: 36

                    CompassHeadingIndicator
                    {
                        compassSize: parent.height * 4        // ← small size for map marker
                        heading:     skyXTools.heading
                    }
                }
            }

            // ── Lat/Lon Click Popup ───────────────────────
            Popup
            {
                id:          latLonPopup
                width:       200
                height:      70
                modal:       false
                focus:       false
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                property real clickLat: 0.0
                property real clickLon: 0.0

                x: Math.min(clickX, mapSection.width  - width  - 8)
                y: Math.min(clickY, mapSection.height - height - 8)

                property real clickX: 0
                property real clickY: 0

                background: Rectangle
                {
                    color:        "#1A1E28"
                    radius:       8
                    border.color: root.accentOk
                    border.width: 1
                }

                Column
                {
                    anchors.centerIn: parent
                    spacing: 4

                    QGCLabel
                    {
                        text:           "LAT  " + latLonPopup.clickLat.toFixed(6) + "°"
                        font.pointSize: ScreenTools.smallFontPointSize
                        font.family:    "Courier New"
                        color:          root.textPri
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    QGCLabel
                    {
                        text:           "LON  " + latLonPopup.clickLon.toFixed(6) + "°"
                        font.pointSize: ScreenTools.smallFontPointSize
                        font.family:    "Courier New"
                        color:          root.textPri
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // ── Map Controls overlay ──────────────────────
        Column {
            anchors.right:        parent.right
            anchors.top:          parent.top
            anchors.rightMargin:  8
            anchors.topMargin:    8
            spacing: 4
            z: 10  // above map
            visible: connected  // ← no point showing zoom buttons when disconnected


            // Zoom In
            Rectangle {
                width:  32
                height: 32
                radius: 6
                color:  "#1A1E28"
                border.color: "#252B3A"
                border.width: 1
                opacity: 0.9

                QGCLabel {
                    text:            "+"
                    font.pointSize:  ScreenTools.mediumFontPointSize
                    color:           root.accentOk
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked:    miniMap.zoomLevel = Math.min(miniMap.zoomLevel + 1, 20)
                }
            }

            // Zoom Out
            Rectangle {
                width:  32
                height: 32
                radius: 6
                color:  "#1A1E28"
                border.color: "#252B3A"
                border.width: 1
                opacity: 0.9

                QGCLabel {
                    text:            "-"
                    font.pointSize:  ScreenTools.mediumFontPointSize
                    color:           root.accentOk
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked:    miniMap.zoomLevel = Math.max(miniMap.zoomLevel - 1, 2)
                }
            }

            // Center on drone
            Rectangle {
                width:  32
                height: 32
                radius: 6
                color:  "#1A1E28"
                border.color: "#252B3A"
                border.width: 1
                opacity: 0.9

                QGCLabel {
                    text:            "⌖"
                    font.pointSize:  ScreenTools.mediumFontPointSize
                    color:           root.accentOk
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // re-center map on drone
                        miniMap.center = QtPositioning.coordinate(
                            skyXTools.latitude,
                            skyXTools.longitude
                        )
                    }
                }
            }

            // ── Follow / Pan Toggle ───────────────────────
            Rectangle
            {
                width:  32
                height: 32
                radius: 6
                color:  followDrone ? root.accentOk : "#1A1E28"
                border.color: followDrone ? root.accentOk : "#252B3A"
                border.width: 1
                opacity: 0.9

                QGCLabel
                {
                    text:            followDrone ? "⊕" : "⊖"
                    font.pointSize:  ScreenTools.smallFontPointSize
                    font.bold:       true
                    color:           followDrone ? "#12151C" : root.accentOk
                    anchors.centerIn: parent
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked:    root.followDrone = !root.followDrone
                }

                HoverHandler { id: followHover }
                ToolTip.visible: followHover.hovered
                ToolTip.text:    followDrone ? "Following drone — click to pan freely" : "Free pan — click to follow drone"
                ToolTip.delay:   600
            }

            // NSats Indicator
            Rectangle
            {
                width:  32
                height: 32
                radius: 6
                color:  "#1A1E28"
                border.color: "#252B3A"
                border.width: 1
                opacity: 0.9

                Column
                {
                    anchors.centerIn: parent
                    spacing: 1

                    QGCLabel
                    {
                        text:       skyXTools.satellites
                        font.pointSize: ScreenTools.smallFontPointSize
                        font.bold:  true
                        color: skyXTools.satellites >= 6 ? root.accentOk
                             : skyXTools.satellites >= 3 ? "#FFB347"
                             :                             root.accentWarn
                        anchors.horizontalCenter: parent.horizontalCenter
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }

                    QGCLabel
                    {
                        text:           "NSAT"
                        font.pointSize: ScreenTools.smallFontPointSize - 3
                        color:          root.textSec
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                HoverHandler
                {
                    id: satsHover
                }
                ToolTip.visible: satsHover.hovered
                ToolTip.text:    skyXTools.satellites + " satellites visible"
                ToolTip.delay:   600
            }
        }

        SkyXCompass
        {
            anchors.bottom:  parent.bottom
            anchors.right:   parent.right
            anchors.margins: 8
            z:               10
            visible:         connected
            heading:         skyXTools.heading ?? 0
        }

        Rectangle
        {
            anchors.fill: parent
            color:        "black"
            opacity:      0.85
            radius:       10
            visible:      !connected
            z:            999

            MouseArea
            {
               anchors.fill: parent
               enabled:      true
            }

            QGCLabel
            {
               text:               "NO SIGNAL"
               font.bold:          true
               font.pointSize:     ScreenTools.mediumFontPointSize
               font.letterSpacing: 3
               color:              "#55596A"
               anchors.centerIn:   parent
            }
        }
    }
}

