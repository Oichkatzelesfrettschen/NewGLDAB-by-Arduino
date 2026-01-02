# NewGLDAB Quick Start Guide

## Getting Started with Modern Build System

This guide helps you get started with the modernized NewGLDAB build system using PlatformIO.

## Prerequisites

### Software Requirements
- **Python 3.7+**: [Download](https://www.python.org/downloads/)
- **Git**: [Download](https://git-scm.com/downloads/)
- **PlatformIO Core** or **Visual Studio Code with PlatformIO extension**

### Hardware Requirements
- Arduino Pro Mini 328P (16MHz, 5V)
- USB to Serial adapter (FTDI or CH340)
- DN6852-A Hall Effect Sensor
- 4.7kΩ resistor
- Small neodymium magnet
- ESC and brushless motor

### Optional Advanced Hardware
- MPU-9250 or BMI088 IMU
- BMP388 Pressure sensor
- SHT31 Humidity sensor
- MS4525DO Differential pressure sensor

## Installation

### Option 1: PlatformIO Core (Command Line)

1. **Install PlatformIO**
   ```bash
   pip install platformio
   ```

2. **Clone Repository**
   ```bash
   git clone https://github.com/Oichkatzelesfrettschen/NewGLDAB-by-Arduino.git
   cd NewGLDAB-by-Arduino
   ```

3. **Build Firmware**
   ```bash
   pio run -e pro_mini
   ```

4. **Upload to Arduino**
   ```bash
   pio run -e pro_mini --target upload
   ```

### Option 2: Visual Studio Code

1. **Install VS Code**: [Download](https://code.visualstudio.com/)

2. **Install PlatformIO Extension**
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "PlatformIO IDE"
   - Click Install

3. **Open Project**
   - File → Open Folder
   - Select NewGLDAB-by-Arduino directory

4. **Build and Upload**
   - Click PlatformIO icon in sidebar
   - Select "Build" under PROJECT TASKS
   - Select "Upload" to flash firmware

## Basic Configuration

### 1. Hardware Connections

**Hall Sensor (DN6852-A)**
```
Pin 1 (VCC)    → Arduino 5V
Pin 2 (GND)    → Arduino GND
Pin 3 (Signal) → Arduino D6
```

**4.7kΩ Resistor**: Between Signal and VCC (pull-up)

**ESC Connection**
```
ESC Signal → Arduino D5
ESC VCC    → Battery +
ESC GND    → Arduino GND (common ground)
```

**Receiver Connection**
```
CH3 (Throttle) → Arduino D2
VCC            → Arduino VCC
GND            → Arduino GND
```

### 2. Initial Setup

1. **Power on the system** (disconnect motor for safety)

2. **Open Serial Monitor** (9600 baud)
   ```bash
   pio device monitor -b 9600
   ```

3. **Verify sensor readings**
   - Hall sensor value should toggle when magnet approaches
   - Check PWM values from receiver

### 3. ESC Calibration

Before using NewGLDAB, calibrate your ESC:

1. Disconnect NewGLDAB from ESC
2. Follow ESC manufacturer's calibration procedure
3. Reconnect NewGLDAB

### 4. PreGlide Motor Speed Setup

1. **Disconnect ESC and battery**

2. **Set throttle stick to maximum**

3. **Connect ESC and battery**
   - Motor doesn't move
   - LED turns on once, then off
   - LED turns on again

4. **Set throttle to lowest** while LED is ON
   - LED turns off, then on again

5. **While LED is ON**, set throttle to desired PreGlide speed
   - This is the speed motor will run for 1 second before stopping

6. **When motor stops**, lower throttle to minimum

7. **When LED stops blinking**, system returns to normal mode

## Usage

### Normal Operation

1. **Throttle up**: Motor runs normally
2. **Throttle to minimum**: 
   - Red LED turns on
   - Motor runs at PreGlide speed
   - After ~1 second, motor stops
3. **When magnet detected**: 
   - LED turns off
   - Motor stops immediately
   - Wing locks in glide position

### Troubleshooting

**LED doesn't turn on**
- Check Arduino power (should see power LED)
- Verify code uploaded successfully
- Check receiver connection

**Motor doesn't stop**
- Verify Hall sensor connection
- Check magnet polarity (south pole to sensor)
- Ensure magnet passes close to sensor (< 5mm)

**Inconsistent detection**
- Recalibrate magnet position
- Check for electromagnetic interference
- Verify pull-up resistor (4.7kΩ)

**Motor runs continuously**
- Check throttle calibration
- Verify PWM signal from receiver
- Check code for correct sensor type (DN6852 vs DN6851)

## Advanced Features

### Adding IMU Support

1. **Install library dependencies**
   ```bash
   pio lib install "Adafruit MPU6050"
   ```

2. **Connect IMU** (I²C)
   ```
   VCC → 3.3V
   GND → GND
   SCL → A5
   SDA → A4
   ```

3. **Enable in code**
   ```cpp
   #define ENABLE_IMU
   #include <Adafruit_MPU6050.h>
   ```

4. **Rebuild and upload**

### Running Tests

```bash
# Native unit tests
pio test -e native

# On-device tests
pio test -e pro_mini
```

### Formal Verification

```bash
# Install TLA+ tools
wget https://github.com/tlaplus/tlaplus/releases/download/v1.8.0/tla2tools.jar

# Run model checker
java -cp tla2tools.jar tlc2.TLC docs/formal-verification/GLDAB_System.tla

# Install Z3
sudo apt-get install z3

# Run constraint verification
z3 docs/formal-verification/GLDAB_Constraints.smt2
```

## Documentation

### Quick Reference
- **Main README**: Project overview and history
- **Comprehensive Report**: `docs/research/COMPREHENSIVE_RESEARCH_REPORT.md`
- **Implementation Guide**: `docs/research/Implementation_Roadmap.md`
- **API Docs**: Generate with `doxygen Doxyfile`

### Example Code

**Read Hall Sensor:**
```cpp
int sensorPin = 6;
int sensorValue = digitalRead(sensorPin);
if (sensorValue == 0) {  // Magnet detected (DN6852-A)
    // Stop motor
}
```

**Control ESC:**
```cpp
#include <Servo.h>
Servo esc;

void setup() {
    esc.attach(5);
}

void loop() {
    esc.writeMicroseconds(1500);  // Mid throttle
}
```

**Read IMU:**
```cpp
#include <Adafruit_MPU6050.h>
Adafruit_MPU6050 mpu;

void setup() {
    mpu.begin();
}

void loop() {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    Serial.print("Accel X: "); Serial.println(a.acceleration.x);
}
```

## Performance Tips

### Memory Optimization
- Use `F()` macro for string constants
- Minimize dynamic memory allocation
- Use PROGMEM for large constant arrays

### Speed Optimization
- Avoid floating point where possible
- Use lookup tables for trigonometry
- Minimize Serial.print in main loop

### Power Optimization
- Put sensors to sleep when not needed
- Reduce LED usage
- Use sleep modes during idle

## Support

### Getting Help
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Read comprehensive research report
- **Community**: Join discussions

### Contributing
- Fork the repository
- Create feature branch
- Make changes following style guide
- Submit pull request

## Safety Notes

⚠️ **Important Safety Information**

1. **Always disconnect battery** when connecting/disconnecting components
2. **Test without propeller** first
3. **Use proper magnet polarity** (south pole to sensor)
4. **Verify failsafe** on receiver
5. **Check mechanical integrity** before flight
6. **Follow local regulations** for RC aircraft

## Next Steps

1. ✅ Complete basic setup and testing
2. ✅ Calibrate PreGlide motor speed
3. ✅ Perform ground tests
4. 📖 Read Implementation Roadmap for advanced features
5. 🔧 Add IMU for enhanced control
6. 🧪 Implement machine learning algorithms
7. ✈️ Conduct flight tests

## Version Information

- **NewGLDAB Version**: 1.0.0
- **PlatformIO Core**: 6.1+
- **Arduino Framework**: 1.8+
- **Last Updated**: January 2026

## License

This project is open source. See LICENSE file for details.

---

**Happy Flying! 🦅**

For detailed technical information, see the [Comprehensive Research Report](docs/research/COMPREHENSIVE_RESEARCH_REPORT.md).
