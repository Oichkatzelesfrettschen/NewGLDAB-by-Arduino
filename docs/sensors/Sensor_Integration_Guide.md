# Sensor Integration and Fusion Guide

## Overview

This document provides comprehensive guidance on integrating multiple sensors for enhanced ornithopter flight control, including IMU, pressure, humidity, and airspeed sensors, along with sensor fusion algorithms.

## 1. Sensor Hardware Specifications

### 1.1 Current Hardware

#### Hall Effect Sensor (DN6852-A)
- **Type**: Unipolar switch
- **Operating Point**: 45 mT ± 25 mT
- **Release Point**: 30 mT ± 25 mT  
- **Response Time**: < 5 μs
- **Supply Voltage**: 4.5-24V
- **Interface**: Digital output (active low)
- **Purpose**: Wing position detection

**Wiring:**
```
Pin 1: VCC (5V)
Pin 2: Ground
Pin 3: Signal Output → Arduino D6
```

### 1.2 Recommended Additional Sensors

#### Inertial Measurement Unit (IMU)

**Option 1: MPU-9250 (9-axis)**
- **Accelerometer**: ±2/±4/±8/±16g, 16-bit
- **Gyroscope**: ±250/±500/±1000/±2000°/s, 16-bit
- **Magnetometer**: ±4800 μT, 14-bit
- **Interface**: I²C (400kHz) or SPI (20MHz)
- **Update Rate**: 1000 Hz (accel/gyro), 100 Hz (mag)
- **I²C Address**: 0x68 or 0x69

**Option 2: BMI088 (6-axis, high performance)**
- **Accelerometer**: ±3/±6/±12/±24g, 16-bit
- **Gyroscope**: ±125/±250/±500/±1000/±2000°/s, 16-bit
- **Interface**: I²C or SPI
- **Update Rate**: 2000 Hz
- **Better vibration immunity than MPU-9250**

**Wiring (I²C):**
```
VCC → 3.3V (not 5V!)
GND → Ground
SCL → Arduino A5
SDA → Arduino A4
```

#### Barometric Pressure Sensor

**Recommended: BMP388**
- **Range**: 300-1100 hPa
- **Resolution**: 0.016 Pa (~0.13m altitude)
- **Accuracy**: ±0.5 hPa (±4m)
- **Interface**: I²C (3.4MHz) or SPI
- **Update Rate**: 200 Hz
- **I²C Address**: 0x76 or 0x77

**Wiring:**
```
VCC → 3.3V
GND → Ground
SCL → Arduino A5
SDA → Arduino A4
```

#### Humidity/Temperature Sensor

**Recommended: SHT31**
- **Humidity**: 0-100% RH, ±2% accuracy
- **Temperature**: -40 to +125°C, ±0.3°C accuracy
- **Interface**: I²C (1MHz)
- **Response Time**: 2 seconds (humidity)
- **I²C Address**: 0x44 or 0x45

**Wiring:**
```
VCC → 3.3V or 5V
GND → Ground
SCL → Arduino A5
SDA → Arduino A4
```

#### Differential Pressure Sensor (Pitot Tube)

**Recommended: MS4525DO**
- **Range**: ±1 psi (±6.9 kPa)
- **Resolution**: 14-bit (0.05% FS)
- **Interface**: I²C
- **Update Rate**: 1kHz
- **I²C Address**: 0x28

**Purpose**: Airspeed measurement

**Pitot Tube Equation:**
```
v = √(2·Δp/ρ)
```

Where:
- v = airspeed (m/s)
- Δp = differential pressure (Pa)
- ρ = air density (kg/m³)

## 2. I²C Bus Configuration

### 2.1 Multi-Sensor I²C Setup

```cpp
#include <Wire.h>

// I²C addresses
#define IMU_ADDR        0x68
#define PRESSURE_ADDR   0x76
#define HUMIDITY_ADDR   0x44
#define AIRSPEED_ADDR   0x28

void setupI2C() {
    Wire.begin();
    Wire.setClock(400000);  // 400kHz Fast Mode
    
    // Enable internal pull-ups if no external pull-ups
    digitalWrite(SDA, HIGH);
    digitalWrite(SCL, HIGH);
}

// Scan for I²C devices
void scanI2C() {
    Serial.println("Scanning I2C bus...");
    for (byte addr = 1; addr < 127; addr++) {
        Wire.beginTransmission(addr);
        if (Wire.endTransmission() == 0) {
            Serial.print("Found device at 0x");
            Serial.println(addr, HEX);
        }
    }
}
```

### 2.2 Pull-up Resistors

For reliable I²C operation:
- **Resistor Value**: 4.7kΩ (2.2kΩ for short cables)
- **Location**: Between VCC and SDA, VCC and SCL
- **Note**: Arduino has internal pull-ups (~20-50kΩ), but external recommended

## 3. Sensor Calibration

### 3.1 Accelerometer Calibration

**6-Position Calibration Method:**

```cpp
struct AccelCalibration {
    float scale[3];     // Scale factors
    float offset[3];    // Bias offsets
};

AccelCalibration calibrateAccelerometer() {
    AccelCalibration cal;
    
    // Measure in 6 orientations (+X, -X, +Y, -Y, +Z, -Z)
    // Each orientation should read ±1g on respective axis
    
    float measurements[6][3];
    
    // ... collect measurements ...
    
    // Calculate offsets (average of +/- measurements)
    for (int axis = 0; axis < 3; axis++) {
        cal.offset[axis] = (measurements[axis*2][axis] + 
                           measurements[axis*2+1][axis]) / 2.0;
    }
    
    // Calculate scale factors
    for (int axis = 0; axis < 3; axis++) {
        float span = measurements[axis*2][axis] - 
                     measurements[axis*2+1][axis];
        cal.scale[axis] = 2.0 / span;  // Should span 2g
    }
    
    return cal;
}

// Apply calibration
void applyAccelCalibration(float& ax, float& ay, float& az, 
                           const AccelCalibration& cal) {
    ax = (ax - cal.offset[0]) * cal.scale[0];
    ay = (ay - cal.offset[1]) * cal.scale[1];
    az = (az - cal.offset[2]) * cal.scale[2];
}
```

### 3.2 Gyroscope Calibration

**Static Bias Calibration:**

```cpp
struct GyroCalibration {
    float bias[3];
};

GyroCalibration calibrateGyroscope(int samples = 1000) {
    GyroCalibration cal = {0, 0, 0};
    
    // Device must be stationary
    Serial.println("Keep device still...");
    delay(1000);
    
    // Collect samples
    for (int i = 0; i < samples; i++) {
        float gx, gy, gz;
        readGyroscope(gx, gy, gz);
        
        cal.bias[0] += gx;
        cal.bias[1] += gy;
        cal.bias[2] += gz;
        
        delay(1);
    }
    
    // Average
    cal.bias[0] /= samples;
    cal.bias[1] /= samples;
    cal.bias[2] /= samples;
    
    return cal;
}

// Apply calibration
void applyGyroCalibration(float& gx, float& gy, float& gz,
                          const GyroCalibration& cal) {
    gx -= cal.bias[0];
    gy -= cal.bias[1];
    gz -= cal.bias[2];
}
```

### 3.3 Magnetometer Calibration

**Hard-Iron and Soft-Iron Correction:**

```cpp
struct MagCalibration {
    float offset[3];      // Hard-iron offset
    float scale[3][3];    // Soft-iron matrix
};

// Collect data by rotating sensor through full sphere
// Use ellipsoid fitting algorithm
// Simplified version (hard-iron only):

MagCalibration calibrateMagnetometer(int samples = 500) {
    MagCalibration cal;
    
    float min_vals[3] = {9999, 9999, 9999};
    float max_vals[3] = {-9999, -9999, -9999};
    
    Serial.println("Rotate sensor in figure-8 pattern...");
    
    for (int i = 0; i < samples; i++) {
        float mx, my, mz;
        readMagnetometer(mx, my, mz);
        
        min_vals[0] = min(min_vals[0], mx);
        min_vals[1] = min(min_vals[1], my);
        min_vals[2] = min(min_vals[2], mz);
        
        max_vals[0] = max(max_vals[0], mx);
        max_vals[1] = max(max_vals[1], my);
        max_vals[2] = max(max_vals[2], mz);
        
        delay(10);
    }
    
    // Hard-iron offset
    for (int i = 0; i < 3; i++) {
        cal.offset[i] = (max_vals[i] + min_vals[i]) / 2.0;
    }
    
    // Identity scale matrix (simplified)
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            cal.scale[i][j] = (i == j) ? 1.0 : 0.0;
        }
    }
    
    return cal;
}
```

## 4. Sensor Fusion Algorithms

### 4.1 Complementary Filter

**Simple and Efficient for Microcontrollers:**

```cpp
class ComplementaryFilter {
private:
    float alpha;  // Typically 0.98
    float roll, pitch, yaw;
    
public:
    ComplementaryFilter(float alpha = 0.98) 
        : alpha(alpha), roll(0), pitch(0), yaw(0) {}
    
    void update(float ax, float ay, float az,
                float gx, float gy, float gz,
                float dt) {
        // Gyroscope integration (high-pass)
        roll  += gx * dt;
        pitch += gy * dt;
        yaw   += gz * dt;
        
        // Accelerometer angles (low-pass)
        float accel_roll  = atan2(ay, az);
        float accel_pitch = atan2(-ax, sqrt(ay*ay + az*az));
        
        // Complementary fusion
        roll  = alpha * roll  + (1 - alpha) * accel_roll;
        pitch = alpha * pitch + (1 - alpha) * accel_pitch;
        // Yaw requires magnetometer
    }
    
    float getRoll()  { return roll * 57.2958; }   // Convert to degrees
    float getPitch() { return pitch * 57.2958; }
    float getYaw()   { return yaw * 57.2958; }
};
```

### 4.2 Madgwick Filter

**Efficient Gradient Descent Algorithm:**

```cpp
class MadgwickFilter {
private:
    float beta;   // Gain parameter (typically 0.1)
    float q0, q1, q2, q3;  // Quaternion
    
public:
    MadgwickFilter(float beta = 0.1) 
        : beta(beta), q0(1), q1(0), q2(0), q3(0) {}
    
    void update(float gx, float gy, float gz,
                float ax, float ay, float az,
                float dt) {
        // Convert gyro to rad/s
        gx *= 0.0174533;
        gy *= 0.0174533;
        gz *= 0.0174533;
        
        // Normalize accelerometer
        float norm = sqrt(ax*ax + ay*ay + az*az);
        if (norm == 0) return;
        ax /= norm;
        ay /= norm;
        az /= norm;
        
        // Gradient descent algorithm
        float s0, s1, s2, s3;
        float qDot1, qDot2, qDot3, qDot4;
        float _2q0, _2q1, _2q2, _2q3, _4q0, _4q1, _4q2, _8q1, _8q2;
        float q0q0, q1q1, q2q2, q3q3;
        
        // Auxiliary variables
        _2q0 = 2.0f * q0;
        _2q1 = 2.0f * q1;
        _2q2 = 2.0f * q2;
        _2q3 = 2.0f * q3;
        _4q0 = 4.0f * q0;
        _4q1 = 4.0f * q1;
        _4q2 = 4.0f * q2;
        _8q1 = 8.0f * q1;
        _8q2 = 8.0f * q2;
        q0q0 = q0 * q0;
        q1q1 = q1 * q1;
        q2q2 = q2 * q2;
        q3q3 = q3 * q3;
        
        // Gradient calculation
        s0 = _4q0 * q2q2 + _2q2 * ax + _4q0 * q1q1 - _2q1 * ay;
        s1 = _4q1 * q3q3 - _2q3 * ax + 4.0f * q0q0 * q1 - _2q0 * ay - _4q1 + _8q1 * q1q1 + _8q1 * q2q2 + _4q1 * az;
        s2 = 4.0f * q0q0 * q2 + _2q0 * ax + _4q2 * q3q3 - _2q3 * ay - _4q2 + _8q2 * q1q1 + _8q2 * q2q2 + _4q2 * az;
        s3 = 4.0f * q1q1 * q3 - _2q1 * ax + 4.0f * q2q2 * q3 - _2q2 * ay;
        
        norm = sqrt(s0*s0 + s1*s1 + s2*s2 + s3*s3);
        if (norm > 0) {
            s0 /= norm;
            s1 /= norm;
            s2 /= norm;
            s3 /= norm;
        }
        
        // Quaternion derivative from gyroscope
        qDot1 = 0.5f * (-q1 * gx - q2 * gy - q3 * gz) - beta * s0;
        qDot2 = 0.5f * (q0 * gx + q2 * gz - q3 * gy) - beta * s1;
        qDot3 = 0.5f * (q0 * gy - q1 * gz + q3 * gx) - beta * s2;
        qDot4 = 0.5f * (q0 * gz + q1 * gy - q2 * gx) - beta * s3;
        
        // Integrate quaternion rate
        q0 += qDot1 * dt;
        q1 += qDot2 * dt;
        q2 += qDot3 * dt;
        q3 += qDot4 * dt;
        
        // Normalize quaternion
        norm = sqrt(q0*q0 + q1*q1 + q2*q2 + q3*q3);
        q0 /= norm;
        q1 /= norm;
        q2 /= norm;
        q3 /= norm;
    }
    
    void getEuler(float& roll, float& pitch, float& yaw) {
        roll  = atan2(2*(q0*q1 + q2*q3), 1 - 2*(q1*q1 + q2*q2));
        pitch = asin(2*(q0*q2 - q3*q1));
        yaw   = atan2(2*(q0*q3 + q1*q2), 1 - 2*(q2*q2 + q3*q3));
        
        roll  *= 57.2958;
        pitch *= 57.2958;
        yaw   *= 57.2958;
    }
};
```

### 4.3 Extended Kalman Filter (EKF)

**More Accurate but Computationally Intensive:**

See separate document: `Kalman_Filter_Implementation.md`

## 5. Altitude Estimation from Pressure

```cpp
class AltitudeEstimator {
private:
    float p0;  // Sea level pressure reference
    
public:
    AltitudeEstimator() : p0(101325.0) {}
    
    void setReference(float pressure) {
        p0 = pressure;  // Current altitude = 0
    }
    
    float getAltitude(float pressure) {
        // Barometric formula
        const float T0 = 288.15;  // Sea level temp (K)
        const float L = 0.0065;   // Temperature lapse rate (K/m)
        const float R = 287.05;   // Gas constant (J/kg·K)
        const float g = 9.80665;  // Gravity (m/s²)
        
        return (T0/L) * (pow(p0/pressure, R*L/g) - 1.0);
    }
    
    float getVerticalSpeed(float p1, float p2, float dt) {
        // Numerical derivative
        float h1 = getAltitude(p1);
        float h2 = getAltitude(p2);
        return (h2 - h1) / dt;
    }
};
```

## 6. Complete Sensor Integration Example

```cpp
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_BMP3XX.h>
#include <Adafruit_SHT31.h>

Adafruit_MPU6050 mpu;
Adafruit_BMP3XX bmp;
Adafruit_SHT31 sht;

MadgwickFilter attitude;
AltitudeEstimator altimeter;

void setup() {
    Serial.begin(115200);
    Wire.begin();
    
    // Initialize IMU
    if (!mpu.begin()) {
        Serial.println("MPU6050 not found!");
    }
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    
    // Initialize pressure sensor
    if (!bmp.begin_I2C()) {
        Serial.println("BMP388 not found!");
    }
    bmp.setTemperatureOversampling(BMP3_OVERSAMPLING_8X);
    bmp.setPressureOversampling(BMP3_OVERSAMPLING_4X);
    bmp.setIIRFilterCoeff(BMP3_IIR_FILTER_COEFF_3);
    bmp.setOutputDataRate(BMP3_ODR_50_HZ);
    
    // Initialize humidity sensor
    if (!sht.begin(0x44)) {
        Serial.println("SHT31 not found!");
    }
    
    // Set pressure reference
    altimeter.setReference(bmp.readPressure());
}

void loop() {
    static unsigned long last_time = 0;
    unsigned long current_time = millis();
    float dt = (current_time - last_time) / 1000.0;
    last_time = current_time;
    
    // Read IMU
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    // Update attitude filter
    attitude.update(g.gyro.x, g.gyro.y, g.gyro.z,
                   a.acceleration.x, a.acceleration.y, a.acceleration.z,
                   dt);
    
    float roll, pitch, yaw;
    attitude.getEuler(roll, pitch, yaw);
    
    // Read pressure
    float altitude = altimeter.getAltitude(bmp.readPressure());
    
    // Read humidity
    float humidity = sht.readHumidity();
    float temperature = sht.readTemperature();
    
    // Print telemetry
    Serial.print("Roll: "); Serial.print(roll);
    Serial.print(" Pitch: "); Serial.print(pitch);
    Serial.print(" Yaw: "); Serial.print(yaw);
    Serial.print(" Alt: "); Serial.print(altitude);
    Serial.print(" Hum: "); Serial.print(humidity);
    Serial.print(" Temp: "); Serial.println(temperature);
    
    delay(10);  // 100 Hz update rate
}
```

## 7. Power Optimization

```cpp
// Put sensors to sleep when not needed
void sleepSensors() {
    mpu.enableSleep(true);
    bmp.setOutputDataRate(BMP3_ODR_0_006_HZ);  // Minimal rate
    // SHT31 auto-sleeps between readings
}

void wakeSensors() {
    mpu.enableSleep(false);
    bmp.setOutputDataRate(BMP3_ODR_50_HZ);
}
```

---

*This document is part of the NewGLDAB Comprehensive Research Report*
