#include "skyxmanager.h"
#include <QtCore/QApplicationStatic>
#include <QDebug>

#include "../Comms/MAVLinkProtocol.h"
#include "../Comms/LinkManager.h"
#include "../Comms/SerialLink.h"


Q_APPLICATION_STATIC(SkyXManager, _SkyXManagerInstance);

SkyXManager::SkyXManager(QObject *parent)
    : QObject(parent)
{
    qDebug()<<"SkyXManager Constructor is called";

    connect(MAVLinkProtocol::instance(), &MAVLinkProtocol::messageReceived,        this, &SkyXManager::slot_mavlink_data_to_SkyXTools);
    connect(MAVLinkProtocol::instance(), &MAVLinkProtocol::mavlinkMessageStatus,   this, &SkyXManager::slot_mavlink_data_sts_to_SkyXTools);
    connect(LinkManager::instance(), &LinkManager::skyx_manager_comm_err, this, &SkyXManager::slot_comm_erro);

    connect(LinkManager::instance(), &LinkManager::commPortsChanged, this, &SkyXManager::slot_portsChanged);
}

SkyXManager::~SkyXManager()
{

}

void SkyXManager::slot_mavlink_data_to_SkyXTools(LinkInterface *link, const mavlink_message_t &message)
{
    Q_UNUSED(link)

    switch (message.msgid)
    {
        case MAVLINK_MSG_ID_SKYX_STATUS:
        {
            mavlink_skyx_status_t status;
            mavlink_msg_skyx_status_decode(&message, &status);
            qDebug() << "Custom SkyXStatus ID:" << message.msgid;
            str_statusText = QString(status.status_text);
            emit dataChanged();
            break;
        }

        case MAVLINK_MSG_ID_STATUSTEXT:
        {
            mavlink_statustext_t statustext;
            mavlink_msg_statustext_decode(&message, &statustext);

            QString text     = QString(statustext.text).trimmed();
            int     severity = statustext.severity;

            if (severity > MAV_SEVERITY_INFO) break;

            QString prefix;
            switch (severity) {
                case MAV_SEVERITY_EMERGENCY:
                case MAV_SEVERITY_ALERT:
                case MAV_SEVERITY_CRITICAL: prefix = "[CRIT] "; break;
                case MAV_SEVERITY_ERROR:    prefix = "[ERR]  "; break;
                case MAV_SEVERITY_WARNING:  prefix = "[WARN] "; break;
                case MAV_SEVERITY_NOTICE:
                case MAV_SEVERITY_INFO:     prefix = "[INFO] "; break;
                default:                    prefix = "[MSG]  "; break;
            }

            str_statusText = prefix + text + "\n" + str_statusText;
            qDebug() << "StatusText:" << prefix + text;
            emit dataChanged();
            break;
        }

        case MAVLINK_MSG_ID_HEARTBEAT:
        {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&message, &heartbeat);
            b_isArmed = (heartbeat.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
            qDebug() << "Armed:" << b_isArmed;
            emit dataChanged();
            break;
        }

        case MAVLINK_MSG_ID_SYSTEM_TIME:
        {
            mavlink_system_time_t sys_time;
            mavlink_msg_system_time_decode(&message, &sys_time);
            qint64 unix_sec  = sys_time.time_unix_usec / 1000000;
            QDateTime dt     = QDateTime::fromSecsSinceEpoch(unix_sec);
            str_flightUpTime = dt.toString("yyyy-MM-dd HH:mm:ss");
            qDebug() << "System Time:" << str_flightUpTime;
            emit dataChanged();
            break;
        }

        case MAVLINK_MSG_ID_SYS_STATUS:
        {
            mavlink_sys_status_t sys_status;
            mavlink_msg_sys_status_decode(&message, &sys_status);
            f_voltage        = sys_status.voltage_battery / 1000.0f;
            f_batteryVoltage = sys_status.battery_remaining;
            qDebug() << "Voltage:" << f_voltage << "Battery%:" << f_batteryVoltage;
            emit dataChanged();
            break;
        }

        case MAVLINK_MSG_ID_GPS_RAW_INT:
        {
            mavlink_gps_raw_int_t gps;
            mavlink_msg_gps_raw_int_decode(&message, &gps);
            i_satellites = gps.satellites_visible;
            i_gpsFixType = gps.fix_type;
            qDebug() << "Satellites:" << i_satellites << "Fix type:" << i_gpsFixType;
            emit dataChanged();
            break;
        }

        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
        {
            mavlink_global_position_int_t global_pos;
            mavlink_msg_global_position_int_decode(&message, &global_pos);
            f_latitude    = global_pos.lat         / 1e7f;
            f_longitude   = global_pos.lon         / 1e7f;
            f_altitude    = global_pos.relative_alt / 1000.0f;
            f_groundSpeed = sqrtf(
                powf(global_pos.vx / 100.0f, 2) +
                powf(global_pos.vy / 100.0f, 2)
                );
            qDebug() << "Lat:"     << f_latitude
                     << "Lon:"     << f_longitude
                     << "Alt:"     << f_altitude
                     << "GndSpd:"  << f_groundSpeed;
            emit dataChanged();
            break;
        }

        case MAVLINK_MSG_ID_VFR_HUD:
        {
            mavlink_vfr_hud_t vfr;
            mavlink_msg_vfr_hud_decode(&message, &vfr);
            f_heading = vfr.heading;
            qDebug() << "Heading:" << f_heading;
            emit dataChanged();
            break;
        }

        default:
            // qDebug() << "Unhandled Message ID:" << message.msgid;
            break;
    }

    emit dataChanged();
}

void SkyXManager::slot_mavlink_data_sts_to_SkyXTools(int sysid, uint64_t totalSent, uint64_t totalReceived, uint64_t totalLoss, float lossPercent)
{
    qDebug()<<sysid<<totalSent<<totalReceived<<totalLoss<<lossPercent;
}

void SkyXManager::slot_comm_erro(const QString &title, const QString &error)
{
    qDebug()<<"Slot Comm Error in SkyXManager";
    f_batteryVoltage = 0;
    emit dataChanged();
}

SkyXManager *SkyXManager::instance()
{
    return _SkyXManagerInstance();
}

float SkyXManager::get_batteryVoltage() { return f_batteryVoltage; }

float SkyXManager::get_latitude()       { return f_latitude; }

float SkyXManager::get_longitude()      { return f_longitude; }

QString SkyXManager::get_flightMode()     { return str_flightUpTime; }

QString SkyXManager::get_statusText()     { return str_statusText; }


QStringList SkyXManager::availablePorts()
{
    return LinkManager::instance()->serialPorts();
}

QStringList SkyXManager::availableBaudRates()
{
    return LinkManager::instance()->serialBaudRates();
}

void SkyXManager::refreshPorts()
{
    emit portsChanged();
}

void SkyXManager::connectSerial(const QString &port, int baudRate)
{
    bool b_retval = false;
    SerialConfiguration *pSerialConfig = new SerialConfiguration(
        QString("SkyX on %1").arg(port)
        );
    pSerialConfig->setPortName(port);
    pSerialConfig->setBaud(baudRate);
    pSerialConfig->setDynamic(true);

    SharedLinkConfigurationPtr sharedConfig(pSerialConfig);
    _skyxLinkConfig = sharedConfig;  // ← save reference!

    b_retval = LinkManager::instance()->createConnectedLink(_skyxLinkConfig);
    _skyxLinkConfig = LinkManager::instance()->addConfiguration(pSerialConfig); // Mandatory

    qDebug() << "SkyX Connecting:" << port << baudRate;

    if( b_retval)
    {
        qDebug()<<"--------------------- Serial Link is created";
        b_isConnected  = true;
        str_lastPort = port;
        str_activePort = str_lastPort;
        i_lastBaud   = baudRate;
    }
    else
    {
        qDebug()<<"--------------------- Serial Link is not created";
    }
}

void SkyXManager::disconnectSerial()
{
    qDebug() << "----------- Disconnection Initiated -----------";

    if (!_skyxLinkConfig)
    {
        qDebug() << "No active config";
        b_isConnected  = false;
        str_activePort = "";
        emit dataChanged();
        return;
    }

    b_isConnected  = false;
    str_activePort = "";
    str_statusText = "[INFO] Disconnected\n" + str_statusText;
    emit dataChanged();


    LinkInterface* const link = _skyxLinkConfig.get()->link();
    if (link) {
        link->disconnect();
    }

    _skyxLinkConfig = nullptr;

    qDebug() << "reset done";

    emit portsChanged();
}

void SkyXManager::slot_portsChanged()
{
    if (!_skyxLinkConfig) {
        qDebug() << "No active config — just notify QML";
        emit portsChanged();
        return;
    }

    // Check if currently connected port still exists
    if (b_isConnected && !str_activePort.isEmpty())
    {
        bool portStillExists = false;
        for (const QSerialPortInfo &info : QSerialPortInfo::availablePorts())
        {
            if (info.portName() == str_activePort)
            {
                portStillExists = true;
                break;
            }
        }

                // Port was removed — auto disconnect
        if (!portStillExists)
        {
            qDebug() << "Port removed:" << str_activePort << "— auto disconnecting";
            str_statusText = "[WARN] Port " + str_activePort +
                             " removed — disconnected\n" + str_statusText;
            b_isConnected  = false;
            str_activePort = "";
            emit dataChanged();
            emit portsChanged();
            return;
        }
    }

    if (!_skyxLinkConfig)
    {
        emit portsChanged();
        return;
    }

    QList<SharedLinkInterfacePtr> links = LinkManager::instance()->links();
    bool found = false;
    for (const SharedLinkInterfacePtr &link : links)
    {
        if (link->linkConfiguration() == _skyxLinkConfig)
        {
            found = true;
            if (!b_isConnected)
            {
                connect(link.get(), &LinkInterface::disconnected,
                        this, &SkyXManager::slot_linkDisconnected,
                        Qt::UniqueConnection);
                b_isConnected  = true;
                str_activePort = str_lastPort;
                qDebug() << "SkyX Link Connected!";
                emit dataChanged();
            }
            break;
        }
    }

            // Link config exists but link not found — also disconnect
    if (!found && b_isConnected)
    {
        qDebug() << "Link lost — auto disconnecting";
        str_statusText = "[WARN] Link lost — disconnected\n" + str_statusText;
        b_isConnected  = false;
        str_activePort = "";
        emit dataChanged();
    }

    emit portsChanged();
}

void SkyXManager::slot_linkDisconnected()
{
    qDebug() << "Link disconnected — port:" << str_activePort;

    if (b_isConnected)
    {
        str_statusText = "[WARN] Cable unplugged: " + str_activePort +
                         "\n" + str_statusText;
        b_isConnected  = false;
        str_activePort = "";
        emit dataChanged();
        emit portsChanged();
    }
}

void SkyXManager::clearMessages()
{
    str_statusText = "";
    emit dataChanged();
}
