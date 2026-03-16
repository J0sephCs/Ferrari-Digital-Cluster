cmake_minimum_required(VERSION 3.16)
project(ferrari VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS
    Quick
    QuickControls2
    Svg
    Location
    Positioning
    SerialBus
)

qt_standard_project_setup(REQUIRES 6.10.2)

# =========================
# Application target
# =========================
qt_add_executable(appferrari
    main.cpp

    # CAN + vehicle backend
    CAN/VirtualCanBus.h
    CAN/VirtualCanBus.cpp

    VehicleState/VehicleState.h
    VehicleState/VehicleState.cpp
)

# =========================
# QML module
# =========================
qt_add_qml_module(appferrari
    URI ferrari
    VERSION 1.0

    QML_FILES
        Main.qml
        Gauge.qml
        StatusRow.qml
        IconStatusRow.qml
        NavigationLayout.qml
        StandardLayout.qml

    RESOURCES
        assets/cluster.png
        assets/gauge.png
        assets/needle_red.svg
        assets/gearSpeed.png
        assets/vehicle_top_view.jpg
        assets/qtLogo.png

        assets/Icons/oil-temp.png
        assets/Icons/battery.png
        assets/Icons/coolant.png
        assets/Icons/turbo.png
        assets/Icons/lane-assist.png
    

        assets/Indicators/seatBelt.svg
        assets/Indicators/seatBeltRed.svg
        assets/Indicators/abs.svg
        assets/Indicators/fuel.svg
        assets/Indicators/Light_White.svg
        assets/Indicators/Lights.svg
        assets/Indicators/lowBeamWhite.svg
        assets/Indicators/lowBeam.svg
        assets/Indicators/parkingLightWhite.svg
        assets/Indicators/parkingLight.svg
        assets/Indicators/fogLight.svg
        assets/Indicators/fogLightRed.svg
        assets/Indicators/p.svg
        assets/Indicators/p_red.svg
        assets/Indicators/warning.svg
        assets/Indicators/warningRed.svg

)

# =========================
# Include paths
# =========================
target_include_directories(appferrari PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/CAN
    ${CMAKE_CURRENT_SOURCE_DIR}/VehicleState
)

# =========================
# Link Qt modules
# =========================
target_link_libraries(appferrari PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Svg
    Qt6::Location
    Qt6::Positioning
    Qt6::SerialBus
)

# =========================
# Platform properties
# =========================
set_target_properties(appferrari PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING
        ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

# =========================
# Install
# =========================
include(GNUInstallDirs)
install(TARGETS appferrari
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
