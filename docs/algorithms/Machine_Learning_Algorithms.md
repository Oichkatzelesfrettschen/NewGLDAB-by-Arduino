# Machine Learning Algorithms for Flight Control

## Overview

This document describes machine learning approaches for adaptive flight control, situational awareness, and predictive behavior in ornithopter systems.

## 1. Multi-Layer Perceptron (MLP) for Flight Mode Classification

### 1.1 Network Architecture

**Input Layer** (12 neurons):
```
x = [θ_wing, ω_wing, p, T, H, v_wind, a_x, a_y, a_z, ω_x, ω_y, ω_z]
```

Where:
- `θ_wing`: Wing angle (degrees)
- `ω_wing`: Wing angular velocity (rad/s)
- `p`: Atmospheric pressure (hPa)
- `T`: Temperature (°C)
- `H`: Humidity (%)
- `v_wind`: Wind speed estimate (m/s)
- `a_x, a_y, a_z`: Linear accelerations (m/s²)
- `ω_x, ω_y, ω_z`: Angular velocities (rad/s)

**Hidden Layers**:
- Layer 1: 24 neurons, ReLU activation
- Layer 2: 16 neurons, ReLU activation
- Layer 3: 8 neurons, ReLU activation

**Output Layer** (4 neurons):
```
y = [P_flapping, P_gliding, P_transitional, P_critical]
```

Probability distribution over flight modes (softmax activation).

### 1.2 Lightweight Implementation

For Arduino microcontrollers, use quantized integer arithmetic:

```cpp
// 8-bit quantized MLP inference
class QuantizedMLP {
private:
    // Pre-trained weights (quantized to int8)
    static const int8_t W1[12][24];  // Input to hidden 1
    static const int8_t W2[24][16];  // Hidden 1 to hidden 2
    static const int8_t W3[16][8];   // Hidden 2 to hidden 3
    static const int8_t W4[8][4];    // Hidden 3 to output
    
    // Bias terms
    static const int8_t B1[24];
    static const int8_t B2[16];
    static const int8_t B3[8];
    static const int8_t B4[4];
    
    // Scaling factors
    static constexpr float SCALE_INPUT = 127.0f;
    static constexpr float SCALE_OUTPUT = 127.0f;
    
    // ReLU activation
    inline int8_t relu(int16_t x) {
        return (x > 0) ? min(x, 127) : 0;
    }
    
public:
    // Forward pass
    void predict(float input[12], float output[4]) {
        int8_t h1[24], h2[16], h3[8];
        int8_t x[12];
        
        // Quantize input
        for (int i = 0; i < 12; i++) {
            x[i] = constrain(input[i] * SCALE_INPUT, -127, 127);
        }
        
        // Layer 1
        for (int i = 0; i < 24; i++) {
            int16_t sum = B1[i];
            for (int j = 0; j < 12; j++) {
                sum += (int16_t)W1[j][i] * x[j] / 128;
            }
            h1[i] = relu(sum);
        }
        
        // Layer 2
        for (int i = 0; i < 16; i++) {
            int16_t sum = B2[i];
            for (int j = 0; j < 24; j++) {
                sum += (int16_t)W2[j][i] * h1[j] / 128;
            }
            h2[i] = relu(sum);
        }
        
        // Layer 3
        for (int i = 0; i < 8; i++) {
            int16_t sum = B3[i];
            for (int j = 0; j < 16; j++) {
                sum += (int16_t)W3[j][i] * h2[j] / 128;
            }
            h3[i] = relu(sum);
        }
        
        // Output layer
        int8_t y[4];
        for (int i = 0; i < 4; i++) {
            int16_t sum = B4[i];
            for (int j = 0; j < 8; j++) {
                sum += (int16_t)W4[j][i] * h3[j] / 128;
            }
            y[i] = constrain(sum, -127, 127);
        }
        
        // Softmax (approximate with exponential lookup table)
        float exp_sum = 0;
        float exp_vals[4];
        for (int i = 0; i < 4; i++) {
            exp_vals[i] = fastExp(y[i] / SCALE_OUTPUT);
            exp_sum += exp_vals[i];
        }
        
        for (int i = 0; i < 4; i++) {
            output[i] = exp_vals[i] / exp_sum;
        }
    }
    
private:
    // Fast exponential approximation
    float fastExp(float x) {
        // Use lookup table or polynomial approximation
        // For embedded systems, use: e^x ≈ (1 + x/256)^256
        x = constrain(x, -10, 10);
        return exp(x);  // Replace with LUT in production
    }
};
```

### 1.3 Training Process

**Dataset Collection:**
1. Log flight data with labeled flight modes
2. Minimum 1000 samples per mode
3. Include various environmental conditions

**Training Pipeline:**
```python
import numpy as np
import tensorflow as tf

# Define model
model = tf.keras.Sequential([
    tf.keras.layers.Dense(24, activation='relu', input_shape=(12,)),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(4, activation='softmax')
])

# Compile
model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# Train
history = model.fit(
    X_train, y_train,
    epochs=100,
    batch_size=32,
    validation_split=0.2
)

# Quantize for deployment
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Export weights for Arduino
weights = model.get_weights()
# Convert to int8 and export as C arrays
```

## 2. Adaptive Control with Recursive Least Squares

### 2.1 RLS Algorithm

Real-time parameter estimation for adaptive control:

```cpp
class RecursiveLeastSquares {
private:
    static constexpr int N = 4;  // Number of parameters
    float theta[N];              // Parameter estimates
    float P[N][N];               // Covariance matrix
    float lambda;                // Forgetting factor (0.95-0.99)
    
public:
    RecursiveLeastSquares(float forgetting_factor = 0.98) 
        : lambda(forgetting_factor) {
        // Initialize
        for (int i = 0; i < N; i++) {
            theta[i] = 0;
            for (int j = 0; j < N; j++) {
                P[i][j] = (i == j) ? 1000.0f : 0.0f;
            }
        }
    }
    
    void update(float x[N], float y) {
        // Prediction error
        float y_pred = 0;
        for (int i = 0; i < N; i++) {
            y_pred += theta[i] * x[i];
        }
        float error = y - y_pred;
        
        // Compute gain: K = P*x / (lambda + x'*P*x)
        float Px[N];
        float xPx = 0;
        for (int i = 0; i < N; i++) {
            Px[i] = 0;
            for (int j = 0; j < N; j++) {
                Px[i] += P[i][j] * x[j];
            }
            xPx += x[i] * Px[i];
        }
        
        float K[N];
        float denominator = lambda + xPx;
        for (int i = 0; i < N; i++) {
            K[i] = Px[i] / denominator;
        }
        
        // Update parameters: theta = theta + K*error
        for (int i = 0; i < N; i++) {
            theta[i] += K[i] * error;
        }
        
        // Update covariance: P = (P - K*x'*P) / lambda
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                P[i][j] = (P[i][j] - K[i] * Px[j]) / lambda;
            }
        }
    }
    
    float getParameter(int index) {
        return (index < N) ? theta[index] : 0;
    }
};
```

### 2.2 Application to Wing Control

```cpp
// Adaptive wing controller
class AdaptiveWingController {
private:
    RecursiveLeastSquares rls;
    
public:
    float computeControl(float wing_angle, float target_angle,
                        float wing_velocity, float wind_disturbance) {
        // Regressor: [angle_error, velocity, wind, constant]
        float x[4];
        x[0] = target_angle - wing_angle;
        x[1] = wing_velocity;
        x[2] = wind_disturbance;
        x[3] = 1.0f;
        
        // Control output
        float u = 0;
        for (int i = 0; i < 4; i++) {
            u += rls.getParameter(i) * x[i];
        }
        
        // Update RLS with actual wing response
        float y = wing_velocity;  // Measured output
        rls.update(x, y);
        
        return u;
    }
};
```

## 3. Situational Awareness State Machine

### 3.1 State Definitions

```cpp
enum FlightState {
    GROUNDED,
    TAKEOFF,
    POWERED_FLIGHT,
    GLIDING,
    LANDING,
    EMERGENCY
};

class SituationalAwareness {
private:
    FlightState current_state;
    QuantizedMLP mlp;
    float state_confidence;
    
public:
    SituationalAwareness() 
        : current_state(GROUNDED), state_confidence(1.0) {}
    
    void update(SensorData& sensors) {
        // Prepare input features
        float features[12] = {
            sensors.wing_angle,
            sensors.wing_velocity,
            sensors.pressure,
            sensors.temperature,
            sensors.humidity,
            sensors.wind_speed,
            sensors.accel_x,
            sensors.accel_y,
            sensors.accel_z,
            sensors.gyro_x,
            sensors.gyro_y,
            sensors.gyro_z
        };
        
        // Run MLP inference
        float probabilities[4];
        mlp.predict(features, probabilities);
        
        // Determine most likely state
        int max_idx = 0;
        float max_prob = probabilities[0];
        for (int i = 1; i < 4; i++) {
            if (probabilities[i] > max_prob) {
                max_prob = probabilities[i];
                max_idx = i;
            }
        }
        
        state_confidence = max_prob;
        
        // State transitions with hysteresis
        FlightState new_state = mapToFlightState(max_idx);
        if (state_confidence > 0.8) {
            current_state = new_state;
        }
    }
    
    FlightState getState() { return current_state; }
    float getConfidence() { return state_confidence; }
    
private:
    FlightState mapToFlightState(int mlp_output) {
        switch(mlp_output) {
            case 0: return POWERED_FLIGHT;
            case 1: return GLIDING;
            case 2: return POWERED_FLIGHT;  // Transitional
            case 3: return EMERGENCY;
            default: return GROUNDED;
        }
    }
};
```

## 4. Predictive Modeling

### 4.1 Time Series Prediction

Use simple autoregressive model:

```cpp
class TimeSeriesPredictor {
private:
    static constexpr int ORDER = 5;  // AR(5) model
    float coeffs[ORDER];
    float history[ORDER];
    int history_idx;
    
public:
    TimeSeriesPredictor() : history_idx(0) {
        for (int i = 0; i < ORDER; i++) {
            coeffs[i] = 0;
            history[i] = 0;
        }
    }
    
    void update(float value) {
        history[history_idx] = value;
        history_idx = (history_idx + 1) % ORDER;
    }
    
    float predict(int steps_ahead = 1) {
        // AR prediction: y(t+1) = Σ a_i * y(t-i)
        float prediction = 0;
        for (int i = 0; i < ORDER; i++) {
            int idx = (history_idx - 1 - i + ORDER) % ORDER;
            prediction += coeffs[i] * history[idx];
        }
        
        // Multi-step prediction (recursive)
        if (steps_ahead > 1) {
            // Recursively predict
            // For simplicity, assume linear extrapolation
            float trend = history[(history_idx-1+ORDER)%ORDER] - 
                         history[(history_idx-2+ORDER)%ORDER];
            prediction += trend * (steps_ahead - 1);
        }
        
        return prediction;
    }
    
    void setCoefficients(float c[ORDER]) {
        for (int i = 0; i < ORDER; i++) {
            coeffs[i] = c[i];
        }
    }
};
```

### 4.2 Application: Wind Prediction

```cpp
// Predict wind gusts for proactive control
TimeSeriesPredictor wind_predictor;

void loop() {
    float current_wind = estimateWindSpeed();
    wind_predictor.update(current_wind);
    
    // Predict wind 0.5 seconds ahead
    float predicted_wind = wind_predictor.predict(5);  // 5 steps @ 100Hz
    
    // Adjust control gains based on prediction
    if (predicted_wind > 2.0) {
        // Increase damping for expected gust
        pid_controller.setGains(Kp, Ki, Kd * 1.5);
    }
}
```

## 5. Online Learning

### 5.1 Incremental Model Update

```cpp
class OnlineLearner {
private:
    static constexpr int N_FEATURES = 12;
    static constexpr int N_OUTPUTS = 4;
    float learning_rate;
    
    // Simple perceptron weights
    float weights[N_FEATURES][N_OUTPUTS];
    
public:
    OnlineLearner(float lr = 0.01) : learning_rate(lr) {
        // Initialize with small random weights
        for (int i = 0; i < N_FEATURES; i++) {
            for (int j = 0; j < N_OUTPUTS; j++) {
                weights[i][j] = random(-100, 100) / 1000.0f;
            }
        }
    }
    
    void train(float features[N_FEATURES], float target[N_OUTPUTS]) {
        // Forward pass
        float output[N_OUTPUTS] = {0};
        for (int j = 0; j < N_OUTPUTS; j++) {
            for (int i = 0; i < N_FEATURES; i++) {
                output[j] += weights[i][j] * features[i];
            }
        }
        
        // Gradient descent update
        for (int j = 0; j < N_OUTPUTS; j++) {
            float error = target[j] - output[j];
            for (int i = 0; i < N_FEATURES; i++) {
                weights[i][j] += learning_rate * error * features[i];
            }
        }
    }
};
```

## 6. Performance Considerations

### 6.1 Computational Budget

For Arduino Pro Mini (16 MHz ATmega328P):
- **Available**: ~16,000 clock cycles per millisecond
- **MLP inference**: ~5,000 cycles (0.3 ms)
- **RLS update**: ~2,000 cycles (0.125 ms)
- **Sensor reading**: ~1,000 cycles (0.0625 ms)
- **Control computation**: ~500 cycles (0.03 ms)

**Total**: ~8.5k cycles → feasible at 100 Hz

### 6.2 Memory Usage

- MLP weights (quantized): ~1.5 KB
- RLS state: ~100 bytes
- History buffers: ~200 bytes
- **Total**: ~2 KB (fits in 2KB SRAM)

## 7. Training Data Collection

### 7.1 Data Logger

```cpp
void logTrainingData() {
    // Log format: timestamp, features[12], label
    Serial.print(millis());
    Serial.print(",");
    
    // Features
    for (int i = 0; i < 12; i++) {
        Serial.print(features[i]);
        Serial.print(",");
    }
    
    // Manual label (set by operator)
    Serial.println(flight_mode_label);
}
```

### 7.2 Labeling Tool

Create Python script to review and label collected data:
```python
import pandas as pd
import matplotlib.pyplot as plt

# Load data
df = pd.read_csv('flight_log.csv')

# Visualize and label
# ... interactive labeling interface ...

# Export labeled dataset
df.to_csv('labeled_training_data.csv', index=False)
```

---

*This document is part of the NewGLDAB Comprehensive Research Report*
