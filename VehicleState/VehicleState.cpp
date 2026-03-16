#include "VehicleState.h"
#include <QtMath>

double VehicleState::speed() const { return m_speed; }
double VehicleState::rpm() const { return m_rpm; }
VehicleState::Gear VehicleState::gear() const { return m_gearEnum; }

VehicleState::VehicleState(QObject *parent) : QObject(parent), m_speed(0), m_rpm(0), m_gearEnum(Park)
{
}


void VehicleState::processCanFrame(uint32_t id, const QByteArray &frame)
{
    switch (id)
    {

    case 0x100:
    { // Speed (km/h → mph)
        if (frame.size() < 2)
            return;

        uint16_t raw =
            static_cast<uint8_t>(frame[0]) |
            (static_cast<uint8_t>(frame[1]) << 8);

        double newSpeed = raw * 0.01 * 0.621371; // mph

        if (!qFuzzyCompare(newSpeed, m_speed))
        {
            m_speed = newSpeed;
            emit speedChanged();
            updateGear(); // Update gear based on new speed
        }
        break;
    }

    case 0x101:
    { // RPM
        if (frame.size() < 4)
            return;

        uint16_t raw =
            static_cast<uint8_t>(frame[2]) |
            (static_cast<uint8_t>(frame[3]) << 8);

        double newRpm = raw * 0.25;

        if (!qFuzzyCompare(newRpm, m_rpm))
        {
            m_rpm = newRpm;
            emit rpmChanged();
        }
        break;
    }
    }
}


void VehicleState::updateGear()
{

    VehicleState::Gear newGear = m_gearEnum;

    if (m_speed == 0)
    {
        newGear = Park;
    }
    else if (m_speed > 0 && m_speed <= 80)
    {
        newGear = Drive;
    }
    else if (m_speed > 85)
    {
        newGear = Sport;
    }

    if (newGear != m_gearEnum)
    {
        m_gearEnum = newGear;
        emit gearChanged();
    }
}

QString VehicleState::gearText() const
{
    switch (m_gearEnum)
    {
    case Park:
        return "P";
    case Reverse:
        return "R";
    case Neutral:
        return "N";
    case Drive:
        return "D";
    case Sport:
        return "S";
    default:
        return "Unknown";
    }
}


