#pragma once

#include <QObject>
#include <QTimer>
#include <QtMath>
#include <cstdlib> 

class VehicleState : public QObject {
    Q_OBJECT

    Q_PROPERTY(double speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(double rpm READ rpm NOTIFY rpmChanged)

public:
    explicit VehicleState(QObject *parent = nullptr);

    double speed() const;
    double rpm() const;

    enum Gear {
        Park,
        Reverse,
        Neutral,
        Drive,
        Sport
    };

    Q_ENUM(Gear)
    Q_PROPERTY(Gear gear READ gear NOTIFY gearChanged)
    Q_PROPERTY(QString gearText READ gearText NOTIFY gearChanged)

    Gear gear() const;
    QString gearText() const;

public slots:
    void processCanFrame(uint32_t id, const QByteArray &frame);
    // void updateState();
    void updateGear();


signals:
    void speedChanged();
    void rpmChanged();
    void gearChanged();


private:
    double m_speed;
    double m_rpm;
    int m_gear;       


    QTimer* m_simTimer;
    double m_simTargetSpeed; 
    int m_simPhase;           
    double m_simSpeed = 0; 

    Gear m_gearEnum;
};

