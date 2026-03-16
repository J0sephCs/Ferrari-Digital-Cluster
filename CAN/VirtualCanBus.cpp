#include "VirtualCanBus.h"
#include <QtMath>

VirtualCanBus::VirtualCanBus(QObject *parent)
    : QObject(parent)
{
    connect(&m_timer, &QTimer::timeout, this, &VirtualCanBus::generateFrame);
    m_timer.start(100); 
}

void VirtualCanBus::generateFrame()
{
    // Simulate acceleration and braking
    if (m_accelerating)
    {

        m_speed += 2.5;

        if (m_speed >= 180)
        {
            m_speed = 180;
            m_accelerating = false; // start braking
        }
    }
    else
    {

        // If we're braking and above 0
        if (m_speed > 0){
            m_speed -= 3.0;

            if (m_speed <= 0)
            {
                m_speed = 0;
                m_pauseCounter = 0; // start pause
            }
        }
        else{
            // We are at 0 → PAUSE
            m_pauseCounter++;

            if (m_pauseCounter >= m_pauseDuration){
                m_accelerating = true; // resume acceleration
            }
        }
    }

    m_rpm = 800 + (m_speed * 30);

    // Auto gear logic
    if (m_speed == 0)
        m_gear = 0;
    else if (m_speed < 20)
        m_gear = 1;
    else if (m_speed < 60)
        m_gear = 2;
    else if (m_speed < 120)
        m_gear = 3;
    else
        m_gear = 4;

    // ---- Speed Frame (0x100)
    QByteArray speedPayload(2, 0);
    uint16_t rawSpeed = m_speed / 0.01;
    speedPayload[0] = rawSpeed & 0xFF;
    speedPayload[1] = (rawSpeed >> 8) & 0xFF;

    emit frameGenerated(QCanBusFrame(0x100, speedPayload));

    // ---- RPM Frame (0x101)
    QByteArray rpmPayload(4, 0);
    uint16_t rawRpm = m_rpm / 0.25;
    rpmPayload[2] = rawRpm & 0xFF;
    rpmPayload[3] = (rawRpm >> 8) & 0xFF;

    emit frameGenerated(QCanBusFrame(0x101, rpmPayload));

    // ---- Gear Frame (0x102)
    QByteArray gearPayload(1, 0);
    gearPayload[0] = m_gear;

    emit frameGenerated(QCanBusFrame(0x102, gearPayload));
}
