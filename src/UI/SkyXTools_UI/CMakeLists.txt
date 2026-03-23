qt_add_library(SkyX STATIC)
qt_add_qml_module(SkyX
    URI QGroundControl.SkyX
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        SkyXToolsViewer.qml   # ← exact filename must match
        SkyXCompass.qml
    NO_PLUGIN
    QML_FILES SkyXCompass.qml
    QML_FILES SkyXComport.qml
)
