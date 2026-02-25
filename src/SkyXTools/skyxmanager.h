#ifndef SKYXMANAGER_H
#define SKYXMANAGER_H

#include <QtCore/QByteArray>
#include <QtCore/QObject>
#include <QtCore/QString>

#include "LinkInterface.h"

class SkyXManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double  batteryVoltage READ batteryVoltage NOTIFY dataChanged)
    Q_PROPERTY(double  latitude       READ latitude       NOTIFY dataChanged)
    Q_PROPERTY(double  longitude      READ longitude      NOTIFY dataChanged)
    Q_PROPERTY(QString flightMode     READ flightMode     NOTIFY dataChanged)
    Q_PROPERTY(QString statusText     READ statusText     NOTIFY dataChanged)

public:
    SkyXManager(QObject *parent = nullptr);
    ~SkyXManager();
    static SkyXManager *instance();

    void init();
    void update_data_to_gui();
    void print_data_to_terminal();

    double  batteryVoltage();
    double  latitude();
    double  longitude();
    QString flightMode();
    QString statusText();

    void slot_mavlink_data_to_SkyXTools(LinkInterface *link, const mavlink_message_t &message);
    void slot_mavlink_data_sts_to_SkyXTools(int sysid, uint64_t totalSent, uint64_t totalReceived, uint64_t totalLoss, float lossPercent);

signals:
    // This signal tells the QML engine to refresh the displayed values
    void dataChanged();

private:
    // Member Variables
    double  _batteryVoltage = 0.0;
    double  _latitude       = 0.0;
    double  _longitude      = 0.0;
    QString _flightMode     = QStringLiteral("UNKNOWN");
    char    _statusText[50] = "Initializing..."; // Static array as requested
};

#endif  // SKYXMANAGER_H
