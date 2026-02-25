#include "skyxmanager.h"
#include <QtCore/QApplicationStatic>
#include <QDebug>
#include "Comms/MAVLinkProtocol.h"

Q_APPLICATION_STATIC(SkyXManager, _SkyXManagerInstance);

SkyXManager::SkyXManager(QObject *parent)
    : QObject(parent)
{
    qDebug()<<"SkyXManager Constructor is called";

    connect(MAVLinkProtocol::instance(), &MAVLinkProtocol::messageReceived,        this, &SkyXManager::slot_mavlink_data_to_SkyXTools);
    connect(MAVLinkProtocol::instance(), &MAVLinkProtocol::mavlinkMessageStatus,   this, &SkyXManager::slot_mavlink_data_sts_to_SkyXTools);

}

SkyXManager::~SkyXManager()
{

}

void SkyXManager::slot_mavlink_data_to_SkyXTools(LinkInterface *link, const mavlink_message_t &message)
{
    Q_UNUSED(link);
    qDebug()<<"Data Received to Skyxmanager.cpp"<<message.len;

    qDebug()<<"Msg ID"<<message.msgid;

    if (message.msgid == MAVLINK_MSG_ID_SKYX_STATUS)
    {
        mavlink_skyx_status_t status;
        mavlink_msg_skyx_status_decode(&message, &status);

        qDebug()<<status.battery_health<<status.battery_health<<status.flight_counter;
    }
}

void SkyXManager::slot_mavlink_data_sts_to_SkyXTools(int sysid, uint64_t totalSent, uint64_t totalReceived, uint64_t totalLoss, float lossPercent)
{
    qDebug()<<sysid<<totalSent<<totalReceived<<totalLoss<<lossPercent;
}

SkyXManager *SkyXManager::instance()
{
    return _SkyXManagerInstance();
}

double SkyXManager::batteryVoltage() { return _batteryVoltage; }

double SkyXManager::latitude()       { return _latitude; }

double SkyXManager::longitude()      { return _longitude; }

QString SkyXManager::flightMode()     { return _flightMode; }

QString SkyXManager::statusText()     { return QString(_statusText); }
