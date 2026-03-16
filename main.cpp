#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "VehicleState.h"
#include "VirtualCanBus.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    VehicleState vehicleState;
    VirtualCanBus simulator;

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("vehicleState", &vehicleState);



    QObject::connect(&simulator, &VirtualCanBus::frameGenerated,
                     &vehicleState,
                     [&](const QCanBusFrame &frame) {
        vehicleState.processCanFrame(frame.frameId(), frame.payload());
    });

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

        engine.loadFromModule("ferrari", "Main");


     if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}


