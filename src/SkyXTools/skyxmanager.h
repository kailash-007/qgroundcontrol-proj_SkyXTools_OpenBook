#ifndef SKYXMANAGER_H
#define SKYXMANAGER_H

#include <QtCore/QByteArray>
#include <QtCore/QObject>
#include <QtCore/QString>

#include "LinkInterface.h"


class SkyXManager : public QObject
{
    Q_OBJECT
    //Using this we can set the value in qml
    Q_PROPERTY(double  batteryVoltage MEMBER batteryVoltage NOTIFY dataChanged)
    Q_PROPERTY(double  latitude       MEMBER latitude       NOTIFY dataChanged)
    Q_PROPERTY(double  longitude      MEMBER longitude      NOTIFY dataChanged)
    Q_PROPERTY(QString flightMode     MEMBER flightMode     NOTIFY dataChanged)
    Q_PROPERTY(QString statusText     MEMBER statusText     NOTIFY dataChanged)

public:
    SkyXManager(QObject *parent = nullptr);
    ~SkyXManager();
    static SkyXManager *instance();

    void init();
    void update_data_to_gui();
    void print_data_to_terminal();

    double  get_batteryVoltage();
    double  get_latitude();
    double  get_longitude();
    QString get_flightMode();
    QString get_statusText();

    void slot_mavlink_data_to_SkyXTools(LinkInterface *link, const mavlink_message_t &message);
    void slot_mavlink_data_sts_to_SkyXTools(int sysid, uint64_t totalSent, uint64_t totalReceived, uint64_t totalLoss, float lossPercent);

signals:
    // This signal tells the QML engine to refresh the displayed values
    void dataChanged();

private:
    // Member Variables
    double  batteryVoltage = 0.0;
    double  latitude = 0.0;
    double  longitude      = 0.0;
    QString flightMode     = QStringLiteral("UNKNOWN");
    QString statusText     = "Initializing..."; // Static array as requested
};

#endif  // SKYXMANAGER_H
