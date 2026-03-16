#ifndef VIRTUALCANBUS_H
#define VIRTUALCANBUS_H

#include <QObject>
#include <QTimer>
#include <QCanBusFrame>

class VirtualCanBus : public QObject{
    Q_OBJECT


public:
    explicit VirtualCanBus(QObject *parent = nullptr);
    bool m_accelerating = true;
    int m_pauseCounter = 0;
    const int m_pauseDuration = 25;

private:
    QTimer m_timer;
    double m_speed = 0;
    double m_rpm = 800;
    int m_gear = 0;



signals:
    void frameGenerated(const QCanBusFrame &frame);
    
    
private slots:
   void generateFrame();


    

};

#endif
