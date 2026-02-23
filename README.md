# Ferrari Digital-Cluster

A high-performance, visually immersive digital instrument cluster built with **Qt 6 (QML)** and **C++**. This project replicates a "Ferrari-style" aesthetic, featuring dynamic gauges, real-time vehicle telemetry, and integrated navigation.

<table>
  <tr>
    <td><img width="1750" height="790" alt="image" src="https://github.com/user-attachments/assets/c459aaf4-f4bf-4ca5-9c8e-99576e50c5d2" /></td>
    <td><img width="1750" height="790" alt="image" src="https://github.com/user-attachments/assets/0918ff18-9f0e-45d6-971b-b43e5edb8313" /></td>
  </tr>

  <tr>
    <td><img width="1750" height="790" alt="image" src="https://github.com/user-attachments/assets/bbc8ff5e-a944-4818-a283-20c457c4a631" /></td>
    <td><img width="1750" height="790" alt="image" src="https://github.com/user-attachments/assets/1fab8a18-a918-4688-be36-b88abd51710a" /></td>
  </tr>
</table>




## Features

**Dynamic Gauge System**: A custom-drawn central RPM/Speed gauge using QML Canvas 2D with a smooth-rotating needle and reactive redline zones.


* **Dual View Layouts**:
**Standard Mode**: Focused on driving with a central gauge flanked by a side-panel map and telemetry.

* **Navigation Mode**: A full-screen map-centric view with essential vehicle data overlays.


* **Interactive Maps**: Real-time map rendering using `QtLocation` and OpenStreetMap, styled with Carto's "Dark Matter" for a premium look.


* **Live Telemetry**: Integrated rows for monitoring critical vehicle stats like oil temperature, battery voltage, and fuel levels.

* **Startup Sequence**: A professional animation sequence featuring logo fades and UI scaling transitions upon application launch.


## Technology Stack

 
* **Language**: C++17.


  
* **Framework**: Qt 6.8+ (Quick, QuickControls2, Svg, Location, Positioning).


  
* **UI Engine**: QML with Graphical Effects (Qt5Compat).


  
* **Build System**: CMake.



## Project Structure

`main.cpp`: Initializes the application and bridges the `VehicleState` backend with the QML frontend.

 
`Main.qml`: The root entry point for the UI, managing the view state and startup animations.



`Gauge.qml`: Core gauge component utilizing Canvas-based drawing for the dial and ticks.


  
`NavigationLayout.qml` / `StandardLayout.qml`: Defined screen layouts for different driving modes.


 
`StatusRow.qml` / `IconStatusRow.qml`: Reusable components for vehicle telemetry display.



## Getting Started

### Prerequisites

**Qt SDK**: Version 6.8 or higher.
**Compiler**: C++17 compatible (GCC, Clang, or MSVC).
**CMake**: Version 3.16 or higher.

### Building from Source

1. **Clone the repository**:
```bash
git clone https://github.com/your-username/ferrari-cluster.git
cd ferrari-cluster

```


2. **Configure and Build**:
```bash
mkdir build && cd build
cmake ..
cmake --build .

```


3. **Run**:
```bash
./appferrari

```

## Controls

**N-keypress**: Triggers a layout switch.

**Space**: Triggers a "Fade to Black" cinematic transition or reset effect.

**Mouse Interaction**: The map panels in the layouts support panning (click and drag) and zooming (scroll wheel).


## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
