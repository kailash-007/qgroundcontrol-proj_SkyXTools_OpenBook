#ifndef SKYXMANAGER_H
#define SKYXMANAGER_H

#include <QtCore/QByteArray>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QDateTime>
#include <cmath>
#include "LinkInterface.h"

class SkyXManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(float   batteryPct    MEMBER f_batteryVoltage  NOTIFY dataChanged)
    Q_PROPERTY(QString flightUpTime  MEMBER str_flightUpTime  NOTIFY dataChanged)
    Q_PROPERTY(QString statusText    MEMBER str_statusText    NOTIFY dataChanged)
    Q_PROPERTY(float   latitude      MEMBER f_latitude        NOTIFY dataChanged)
    Q_PROPERTY(float   longitude     MEMBER f_longitude       NOTIFY dataChanged)
    Q_PROPERTY(float   batteryVol    MEMBER f_voltage         NOTIFY dataChanged)
    Q_PROPERTY(int     satellites    MEMBER i_satellites      NOTIFY dataChanged)
    Q_PROPERTY(float   heading       MEMBER f_heading         NOTIFY dataChanged)
    Q_PROPERTY(float   altitude      MEMBER f_altitude        NOTIFY dataChanged)
    Q_PROPERTY(float   groundSpeed   MEMBER f_groundSpeed     NOTIFY dataChanged)
    Q_PROPERTY(int     gpsFixType    MEMBER i_gpsFixType      NOTIFY dataChanged)
    Q_PROPERTY(bool    isArmed       MEMBER b_isArmed         NOTIFY dataChanged)
    Q_PROPERTY(bool    isConnected   MEMBER b_isConnected     NOTIFY dataChanged)
    Q_PROPERTY(QString activePort    MEMBER str_activePort    NOTIFY dataChanged)
    Q_PROPERTY(int     activeBaudrate MEMBER i_lastBaud NOTIFY dataChanged)

public:
    SkyXManager(QObject *parent = nullptr);
    ~SkyXManager();

    static SkyXManager *instance();

    void init();
    void update_data_to_gui();
    void print_data_to_terminal();

    float   get_batteryVoltage();
    float   get_latitude();
    float   get_longitude();
    QString get_flightMode();
    QString get_statusText();

    Q_INVOKABLE QStringList availablePorts();
    Q_INVOKABLE QStringList availableBaudRates();
    Q_INVOKABLE void        connectSerial(const QString &port, int baudRate);
    Q_INVOKABLE void        disconnectSerial();
    Q_INVOKABLE void        refreshPorts();
    Q_INVOKABLE void        clearMessages();


public slots:
    void slot_mavlink_data_to_SkyXTools(LinkInterface *link, const mavlink_message_t &message);
    void slot_mavlink_data_sts_to_SkyXTools(int sysid, uint64_t totalSent, uint64_t totalReceived, uint64_t totalLoss, float lossPercent);
    void slot_comm_erro(const QString &title, const QString &error);
    void slot_linkDisconnected();
    void slot_portsChanged();

signals:
    void dataChanged();
    void portsChanged();

private:
    // Battery
    float   f_batteryVoltage = 0.0f;
    float   f_voltage        = 0.0f;

            // Position
    float   f_latitude       = 0.0f;
    float   f_longitude      = 0.0f;
    float   f_altitude       = 0.0f;

            // Movement
    float   f_groundSpeed    = 0.0f;
    float   f_heading        = 0.0f;

            // GPS
    int     i_satellites     = 0;
    int     i_gpsFixType     = 0;

            // Status
    QString str_flightUpTime = QStringLiteral("UNKNOWN");
    QString str_statusText   = QStringLiteral("Initializing...");

            // Armed state
    bool    b_isArmed        = false;

            // Connection
    bool    b_isConnected    = false;
    QString str_activePort   = "";
    QString str_lastPort     = "";
    int     i_lastBaud       = 115200;

    SharedLinkConfigurationPtr _skyxLinkConfig = nullptr;
};

#endif // SKYXMANAGER_H
