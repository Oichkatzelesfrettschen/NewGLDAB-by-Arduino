# Comprehensive Research & Development Report: NewGLDAB Advanced Flight Control System

**Document Version:** 1.0  
**Date:** January 2026  
**Project:** NewGLDAB by Arduino - Advanced Ornithopter Control System

---

## Executive Summary

This comprehensive research report synthesizes mathematical, materials science, fluid mechanics, and computational approaches for the NewGLDAB ornithopter flight control system. The document addresses technical debt (debitum technicum), knowledge gaps (lacunae), and proposes advanced algorithms including quaternion/octonion-based spatial calculations, multi-layer perceptron (MLP) situational awareness, and formal verification using TLA+ and Z3.

---

## Table of Contents

1. [Technical Debt and Knowledge Gaps Analysis](#1-technical-debt-and-knowledge-gaps-analysis)
2. [Materials Science Foundations](#2-materials-science-foundations)
3. [Fluid Mechanics and Aerodynamics](#3-fluid-mechanics-and-aerodynamics)
4. [Mathematical Foundations for Spatial Calculations](#4-mathematical-foundations-for-spatial-calculations)
5. [Machine Learning for Situational Awareness](#5-machine-learning-for-situational-awareness)
6. [Sensor Integration and Hardware Interactions](#6-sensor-integration-and-hardware-interactions)
7. [Stability Tracking and Control Systems](#7-stability-tracking-and-control-systems)
8. [Formal Verification with TLA+ and Z3](#8-formal-verification-with-tla-and-z3)
9. [Build System Modernization](#9-build-system-modernization)
10. [Implementation Roadmap](#10-implementation-roadmap)
11. [References and Bibliography](#11-references-and-bibliography)

---

## 1. Technical Debt and Knowledge Gaps Analysis

### 1.1 Lacunae (Knowledge Gaps) Identification

#### Current System Limitations
- **L1**: Lack of real-time orientation feedback beyond wing position
- **L2**: No environmental sensor integration (pressure, humidity, wind)
- **L3**: Missing predictive flight behavior models
- **L4**: Absence of adaptive control algorithms
- **L5**: No formal verification of safety-critical behavior

#### Mathematical Formulation of Knowledge Gaps

Let `K_current` represent current system knowledge and `K_required` represent required knowledge:

```
Lacuna(i) = K_required(i) ∖ K_current(i)
```

Where the knowledge domains are:
- K₁: Spatial orientation (3D rotation representation)
- K₂: Environmental sensing and modeling
- K₃: Adaptive control theory
- K₄: Formal verification methodology

### 1.2 Debitum Technicum (Technical Debt) Assessment

#### Code Quality Metrics
```
Technical_Debt = Σ(Complexity_i × Maintenance_Cost_i)
```

**Current System Technical Debt:**

1. **Architectural Debt (D₁)**
   - Monolithic Arduino sketch structure
   - Tight coupling between sensor reading and control logic
   - Estimated refactoring effort: 40 hours

2. **Documentation Debt (D₂)**
   - Missing formal specifications
   - Insufficient algorithm documentation
   - Estimated documentation effort: 30 hours

3. **Testing Debt (D₃)**
   - No unit tests
   - No integration tests
   - No formal verification
   - Estimated testing infrastructure: 50 hours

4. **Build System Debt (D₄)**
   - Manual Arduino IDE compilation
   - No dependency management
   - No CI/CD pipeline
   - Estimated modernization effort: 20 hours

**Total Technical Debt:** 140 hours of estimated remediation effort

### 1.3 Priority Matrix

| Gap/Debt | Safety Impact | Performance Impact | Priority |
|----------|--------------|-------------------|----------|
| L1 (Orientation) | High | High | Critical |
| L3 (Predictive) | Medium | High | High |
| D₄ (Build System) | Low | Medium | High |
| L2 (Environmental) | Medium | Medium | Medium |
| D₁ (Architecture) | Low | Medium | Medium |

---

## 2. Materials Science Foundations

### 2.1 Wing Material Properties

#### Structural Analysis

The wing material selection critically affects flight dynamics. Key material properties:

**Young's Modulus (E):**
```
E = σ/ε
```
Where:
- σ = stress (Pa)
- ε = strain (dimensionless)

**Required Properties for Ornithopter Wings:**
- High strength-to-weight ratio: E/ρ > 10⁶ m²/s²
- Flexibility for flapping: ε_max ≈ 2-5%
- Fatigue resistance: N_cycles > 10⁶

#### Recommended Materials

1. **Carbon Fiber Composite**
   - E ≈ 230 GPa
   - ρ ≈ 1.6 g/cm³
   - E/ρ ≈ 143.75 × 10⁶ m²/s²

2. **Balsa Wood (current)**
   - E ≈ 3.7 GPa
   - ρ ≈ 0.16 g/cm³
   - E/ρ ≈ 23.13 × 10⁶ m²/s²

3. **Mylar Film (wing membrane)**
   - Thickness: 12-25 μm
   - ρ ≈ 1.4 g/cm³
   - Tear strength: 5-15 kN/m

### 2.2 Material-Sensor Interaction

#### Magnetic Field Interactions

Hall sensor (DN6852-A) sensitivity to wing materials:

```
B_detected = B_source - B_attenuation(material, distance)
```

Material effects on magnetic field:
- Balsa wood: μᵣ ≈ 1 (no significant attenuation)
- Carbon fiber: slight diamagnetic effect (μᵣ < 1)
- Mylar: μᵣ ≈ 1 (transparent to magnetic fields)

### 2.3 Environmental Degradation

Temperature effects on material properties:

```
E(T) = E₀[1 - α(T - T₀)]
```

Where α is the thermal coefficient of elasticity.

**Critical Considerations:**
- Operating temperature range: -10°C to 50°C
- Humidity effects on balsa: strength reduction up to 20%
- UV degradation of Mylar: implement UV-resistant coating

---

## 3. Fluid Mechanics and Aerodynamics

### 3.1 Aerodynamic Forces

#### Lift Force

```
L = ½ρv²SC_L
```

Where:
- ρ = air density (kg/m³)
- v = airspeed (m/s)
- S = wing area (m²)
- C_L = lift coefficient (function of angle of attack α)

For ornithopter flapping flight:
```
C_L(t) = C_L0 + C_Lα·α(t) + C_Lq·(qc/2v)
```

Where q is pitch rate and c is chord length.

#### Drag Force

```
D = ½ρv²SC_D
```

Total drag coefficient:
```
C_D = C_D0 + C_Di + C_Dw
```

Components:
- C_D0: parasitic drag (friction + form)
- C_Di: induced drag = C_L²/(πeAR)
- C_Dw: wave drag (negligible at low speeds)

### 3.2 Wing Kinematics

#### Flapping Motion

Wing position as function of time:
```
θ(t) = θ₀ + A·sin(2πft)
```

Where:
- θ₀ = neutral position
- A = flapping amplitude
- f = flapping frequency (Hz)

**Current System Parameters:**
- Flapping frequency: ~10-15 Hz
- Amplitude: ~30-40 degrees

#### Reynolds Number

```
Re = ρvL/μ
```

For ornithopter scale (L ≈ 0.3 m, v ≈ 5 m/s):
```
Re ≈ 100,000
```

This is transitional regime between laminar and turbulent flow.

### 3.3 Glide Performance

#### Glide Ratio

```
GR = L/D = C_L/C_D
```

Optimal glide occurs when:
```
∂GR/∂α = 0
```

This is the wing angle that NewGLDAB seeks to maintain.

#### Sink Rate

```
V_sink = W/(L/D)·v_glide
```

Minimizing sink rate maximizes glide duration.

### 3.4 Material-Fluid Interactions

#### Boundary Layer

Laminar boundary layer thickness:
```
δ = 5x/√(Re_x)
```

Where x is distance from leading edge.

**Practical Impact:**
- Wing surface roughness: < 0.1 mm for laminar flow
- Balsa grain orientation affects boundary layer
- Membrane flexibility allows passive flow control

#### Wing Flexibility Effects

Fluid-structure interaction:
```
m∂²y/∂t² + c∂y/∂t + ky = F_aero(y, ∂y/∂t)
```

This coupling requires computational fluid dynamics (CFD) for full analysis.

---

## 4. Mathematical Foundations for Spatial Calculations

### 4.1 Quaternion Rotation Mathematics

#### Quaternion Definition

A quaternion represents 3D rotation:
```
q = w + xi + yj + zk
```

Where:
- w, x, y, z ∈ ℝ
- i² = j² = k² = ijk = -1
- ||q|| = 1 for unit quaternions

#### Rotation Representation

To rotate vector v by quaternion q:
```
v' = qvq*
```

Where q* is the quaternion conjugate: q* = w - xi - yj - zk

#### Advantages Over Euler Angles
1. No gimbal lock
2. Smooth interpolation (SLERP)
3. Compact representation (4 values vs 9 for rotation matrix)
4. Numerically stable

#### Quaternion Operations

**Composition (sequential rotations):**
```
q_total = q₂ ⊗ q₁
```

Where ⊗ is quaternion multiplication:
```
q₂ ⊗ q₁ = (w₂w₁ - v₂·v₁, w₂v₁ + w₁v₂ + v₂ × v₁)
```

**Conversion from axis-angle:**
```
q = (cos(θ/2), sin(θ/2)·n̂)
```

Where n̂ is unit rotation axis and θ is rotation angle.

### 4.2 Octonion Rotation Theory

#### Octonion Definition

Octonions extend quaternions to 8 dimensions:
```
o = r + xi + yj + zk + we + xie + yje + zke
```

Properties:
- Non-commutative: ab ≠ ba
- Non-associative: (ab)c ≠ a(bc)
- Normed division algebra

#### Applications in Flight Control

While quaternions handle 3D rotation (SO(3)), octonions can represent:
1. Combined translation and rotation (SE(3))
2. Higher-dimensional control spaces
3. Multi-body dynamics (multiple wing segments)

#### Octonion Rotation Formula

For constrained systems (maintaining certain properties):
```
v' = o₁vo₂*
```

Where o₁ and o₂ are related by system constraints.

**Practical Application:**
- Model coupled wing-body dynamics
- Represent flexible wing deformation states
- Handle sensor fusion from multiple reference frames

### 4.3 Gimbal Lock Problem

#### Euler Angle Singularity

Using Euler angles (roll φ, pitch θ, yaw ψ):
```
R = R_z(ψ)R_y(θ)R_x(φ)
```

At θ = ±90°, system loses one degree of freedom.

#### Quaternion Solution

Quaternion representation avoids this singularity:
```
∂q/∂t = ½Ω(ω)q
```

Where Ω(ω) is skew-symmetric matrix of angular velocity ω.

### 4.4 Spatial Transformation Chain

#### Complete Orientation Pipeline

```
Sensor Frame → Body Frame → Navigation Frame → Earth Frame
```

Each transformation represented by quaternion:
```
q_earth = q_nav ⊗ q_body ⊗ q_sensor
```

**Implementation Considerations:**
- Update rate: 100-1000 Hz
- Numerical stability: normalize quaternions every iteration
- Integration: use Runge-Kutta 4th order

---

## 5. Machine Learning for Situational Awareness

### 5.1 Multi-Layer Perceptron (MLP) Architecture

#### Network Structure

**Input Layer (12 neurons):**
```
x = [θ_wing, ω_wing, p, T, H, v_wind, a_x, a_y, a_z, ω_x, ω_y, ω_z]ᵀ
```

Where:
- θ_wing: wing angle
- ω_wing: wing angular velocity
- p: pressure
- T: temperature
- H: humidity
- v_wind: wind speed
- a_x, a_y, a_z: accelerations
- ω_x, ω_y, ω_z: angular velocities

**Hidden Layers:**
```
Layer 1: 24 neurons (ReLU activation)
Layer 2: 16 neurons (ReLU activation)
Layer 3: 8 neurons (ReLU activation)
```

**Output Layer (4 neurons):**
```
y = [flight_mode, stability_score, optimal_wing_angle, confidence]ᵀ
```

#### Activation Functions

```
ReLU(x) = max(0, x)
Softmax(x_i) = exp(x_i) / Σexp(x_j)
```

### 5.2 Training Methodology

#### Loss Function

```
L = L_classification + λ₁L_regression + λ₂L_physics
```

Components:
1. **Classification Loss** (flight mode):
   ```
   L_classification = -Σy_i·log(ŷ_i)
   ```

2. **Regression Loss** (optimal angle):
   ```
   L_regression = ||θ_predicted - θ_optimal||²
   ```

3. **Physics-Informed Loss** (constraint satisfaction):
   ```
   L_physics = ||f(state, action) - d(state)/dt||²
   ```

### 5.3 Real-Time Inference

#### Computational Complexity

Forward pass through network:
```
Flops = 2(Σ(n_i × n_{i+1}))
      ≈ 2(12×24 + 24×16 + 16×8 + 8×4)
      = 1,536 operations
```

**Feasibility on Arduino:**
- Arduino Pro Mini: 16 MHz, 8-bit AVR
- Required: ~1.5k FLOPs at 100 Hz = 150k FLOPS
- Limitation: Insufficient computational power

**Solution:** Use lightweight models or external processor

### 5.4 Online Learning and Adaptation

#### Recursive Least Squares (RLS)

For adaptive parameter estimation:
```
θ(k+1) = θ(k) + P(k+1)x(k)[y(k) - x(k)ᵀθ(k)]
P(k+1) = [P(k) - P(k)x(k)x(k)ᵀP(k)/(λ + x(k)ᵀP(k)x(k))]/λ
```

**Advantages:**
- Computationally efficient
- Suitable for microcontroller implementation
- Provides confidence bounds

### 5.5 Situational Awareness States

#### State Classification

**State Vector:**
```
S = [position, velocity, orientation, environment, wing_config]
```

**Awareness Categories:**
1. **Normal Flight** (P > 0.8)
2. **Transitional** (0.5 < P < 0.8)
3. **Unstable** (0.2 < P < 0.5)
4. **Critical** (P < 0.2)

Where P is confidence probability.

#### Decision Making

Bayesian decision theory:
```
action* = argmax_a E[U(s, a)|observations]
```

---

## 6. Sensor Integration and Hardware Interactions

### 6.1 Sensor Suite Specification

#### Primary Sensors

1. **Hall Effect Sensor (DN6852-A)**
   - Type: Unipolar switch
   - Operate point: 45 mT ± 25 mT
   - Release point: 30 mT ± 25 mT
   - Response time: < 5 μs

2. **Inertial Measurement Unit (IMU) - Proposed**
   - **Accelerometer:** ±16g range, 14-bit resolution
   - **Gyroscope:** ±2000°/s range, 16-bit resolution
   - **Magnetometer:** ±4900 μT range
   - Example: MPU-9250, BMI088, or LSM6DSO

3. **Barometric Pressure Sensor - Proposed**
   - Range: 300-1100 hPa
   - Resolution: 0.01 hPa (~0.1m altitude)
   - Example: BMP388, MS5611

4. **Temperature/Humidity Sensor - Proposed**
   - Temperature: -40 to +85°C, ±0.3°C accuracy
   - Humidity: 0-100% RH, ±2% accuracy
   - Example: SHT31, BME280

5. **Pitot Tube / Airspeed Sensor - Proposed**
   - Differential pressure: 0-1 kPa
   - Resolution: 0.1 Pa (~0.1 m/s)
   - Example: MS4525DO

### 6.2 Sensor Fusion Mathematics

#### Kalman Filter Framework

**State Estimation:**
```
x = [position, velocity, orientation, angular_velocity, sensor_biases]ᵀ
```

**Prediction:**
```
x̂⁻(k) = Fx̂(k-1) + Bu(k)
P⁻(k) = FP(k-1)Fᵀ + Q
```

**Update:**
```
K(k) = P⁻(k)Hᵀ[HP⁻(k)Hᵀ + R]⁻¹
x̂(k) = x̂⁻(k) + K(k)[z(k) - Hx̂⁻(k)]
P(k) = [I - K(k)H]P⁻(k)
```

Matrices:
- F: state transition (derived from dynamics)
- B: control input mapping
- H: measurement model
- Q: process noise covariance
- R: measurement noise covariance

#### Complementary Filter (Lightweight Alternative)

For orientation estimation:
```
θ(k) = α·(θ(k-1) + ω·Δt) + (1-α)·θ_accel
```

Where:
- α ≈ 0.98 (high-pass filter on gyroscope)
- (1-α): low-pass filter on accelerometer

### 6.3 Hardware Communication Protocols

#### I²C Bus Configuration

```
SCL frequency: 400 kHz (Fast Mode)
Pull-up resistors: 4.7kΩ
```

**Address Map:**
- 0x68: IMU (MPU-9250)
- 0x76: Pressure sensor (BMP388)
- 0x44: Humidity sensor (SHT31)
- 0x28: Airspeed sensor (MS4525DO)

#### SPI Alternative (Higher Speed)

```
Clock frequency: 8 MHz
Mode: CPOL=0, CPHA=0
```

Advantages: Higher bandwidth, dedicated lines
Disadvantages: More pins required

### 6.4 Sensor Calibration

#### Accelerometer Calibration

Six-position calibration:
```
[x, y, z] measured at [±1g, ±1g, ±1g] orientations
```

Calibration parameters:
```
a_cal = S·(a_raw - b)
```

Where:
- S: 3×3 scale/alignment matrix
- b: 3×1 bias vector

#### Gyroscope Calibration

Static calibration (zero angular velocity):
```
bias_ω = mean(ω_raw) over 10 seconds
ω_cal = ω_raw - bias_ω
```

Temperature compensation:
```
bias_ω(T) = bias_ω0 + k·(T - T0)
```

#### Magnetometer Calibration

Hard-iron and soft-iron correction:
```
m_cal = A(m_raw - b)
```

Where:
- A: 3×3 soft-iron matrix
- b: 3×1 hard-iron offset

Calibration procedure: rotate sensor through full sphere.

### 6.5 Power Management

#### Power Budget

| Component | Current (mA) | Duty Cycle | Average (mA) |
|-----------|--------------|------------|--------------|
| Arduino Pro Mini | 20 | 100% | 20 |
| Hall Sensor | 5 | 100% | 5 |
| IMU | 3.5 | 100% | 3.5 |
| Pressure Sensor | 0.7 | 50% | 0.35 |
| Humidity Sensor | 0.4 | 10% | 0.04 |
| Motor (glide) | 0 | 0% | 0 |
| **Total** | | | **28.9 mA** |

**Battery Life Calculation:**
```
Life = Battery_capacity / Average_current
     = 150 mAh / 28.9 mA
     ≈ 5.2 hours
```

---

## 7. Stability Tracking and Control Systems

### 7.1 Stability Criteria

#### Lyapunov Stability

A system is stable if there exists a Lyapunov function V(x) such that:
```
V(x) > 0 for x ≠ 0
V̇(x) < 0 for x ≠ 0
```

For ornithopter flight:
```
V(x) = ½(ω - ω_d)ᵀI(ω - ω_d) + ½k_θ(θ - θ_d)²
```

Where:
- I: moment of inertia tensor
- ω: angular velocity
- θ: attitude angles
- subscript d denotes desired values

### 7.2 Control System Architecture

#### Cascade Control Structure

```
Outer Loop (Position/Velocity):
    Input: desired_position → Output: desired_attitude
    Update rate: 10-50 Hz

Inner Loop (Attitude/Rate):
    Input: desired_attitude → Output: motor_commands
    Update rate: 100-500 Hz
```

#### PID Controller Design

**Angular rate control:**
```
u(t) = K_p·e(t) + K_i∫e(τ)dτ + K_d·de/dt
```

**Tuning Guidelines:**
```
K_p: Start with J·ω_n² where ω_n is natural frequency
K_i: K_p / (4ζω_n)
K_d: 2ζω_n·K_p
```

ζ = 0.7 (critical damping ratio for flight control)

### 7.3 Gyroscope Integration

#### Rate Gyro Processing

**Angular velocity to attitude:**
```
θ(k) = θ(k-1) + ω(k)·Δt
```

**Drift compensation:**
```
θ_fused = α·θ_gyro + (1-α)·θ_accel
```

#### Stability Detection

Classify stability based on angular acceleration:
```
Stability_Index = exp(-||ω̇||²/σ²)
```

Where σ is threshold parameter (typical: 10 rad/s²).

**Stability States:**
- SI > 0.8: Stable
- 0.5 < SI < 0.8: Moderately stable
- SI < 0.5: Unstable

### 7.4 Environmental Disturbance Rejection

#### Wind Gust Modeling

von Kármán turbulence spectrum:
```
Φ(ω) = σ²L/π · [1 + (Lω/V)²]^(-5/6)
```

Where:
- σ: turbulence intensity
- L: turbulence scale length
- V: airspeed

#### Adaptive Control

**Model Reference Adaptive Control (MRAC):**
```
u = -K_x·x - K_r·r + K_ff·r_d
```

Adaptation law:
```
dK/dt = -Γ·e·xᵀ
```

Where Γ is adaptation gain and e is tracking error.

### 7.5 Pressure-Based Altitude Control

#### Altitude Estimation

```
h = (T₀/L)[(p₀/p)^(RL/g₀) - 1]
```

Where:
- T₀ = 288.15 K (sea level temperature)
- L = 0.0065 K/m (temperature lapse rate)
- p₀ = 101325 Pa (sea level pressure)
- R = 287.05 J/(kg·K) (gas constant)
- g₀ = 9.80665 m/s²

#### Vertical Speed

```
v_z = -dp/dt / (ρg)
```

Using derivative of pressure measurement.

### 7.6 Humidity Effects on Flight

#### Air Density Correction

Humid air is less dense:
```
ρ_humid = ρ_dry(1 - 0.378·e/p)
```

Where:
- e: water vapor pressure (from humidity)
- p: total pressure

**Impact on Lift:**
```
ΔL/L ≈ -0.378·e/p
```

At 100% RH and 25°C: ~2% reduction in lift.

---

## 8. Formal Verification with TLA+ and Z3

### 8.1 TLA+ Specification

#### System Model

TLA+ (Temporal Logic of Actions) provides formal specification for concurrent systems.

**State Variables:**
```tla
VARIABLES 
    wing_angle,      \* Current wing position [0..360]
    motor_state,     \* {stopped, running, transitioning}
    throttle,        \* Input throttle [900..2000]
    sensor_detected, \* Boolean: magnet detected
    led_state,       \* Boolean: LED on/off
    timer,           \* PreGlide timer count
    mode             \* {normal, calibration, preglide}
```

**Type Invariants:**
```tla
TypeOK == 
    /\ wing_angle \in [0..360]
    /\ motor_state \in {"stopped", "running", "transitioning"}
    /\ throttle \in [900..2000]
    /\ sensor_detected \in BOOLEAN
    /\ led_state \in BOOLEAN
    /\ timer \in Nat
    /\ mode \in {"normal", "calibration", "preglide"}
```

**Safety Property:**
```tla
SafetyProperty == 
    /\ motor_state = "running" => throttle > 950
    /\ sensor_detected => motor_state = "stopped"
    /\ mode = "preglide" => led_state = TRUE
```

**Liveness Property:**
```tla
LivenessProperty ==
    /\ (throttle < 950) ~> (mode = "preglide")
    /\ (sensor_detected) ~> (motor_state = "stopped")
    /\ (mode = "calibration") ~> (mode = "normal")
```

#### Complete TLA+ Specification

See: [`docs/formal-verification/GLDAB_System.tla`](../formal-verification/GLDAB_System.tla)

### 8.2 Z3 Constraint Solving

#### System Constraints

Z3 is a satisfiability modulo theories (SMT) solver for constraint verification.

**Wing Angle Constraints:**
```smt2
(declare-const wing_angle Real)
(declare-const optimal_angle Real)
(declare-const sensor_threshold Real)

(assert (and (>= wing_angle 0.0) (<= wing_angle 360.0)))
(assert (and (>= optimal_angle 0.0) (<= optimal_angle 360.0)))
(assert (= sensor_threshold 45.0))

; Sensor detection occurs at optimal angle
(assert (=> (sensor_detected) 
            (< (abs (- wing_angle optimal_angle)) 5.0)))
```

**Timing Constraints:**
```smt2
(declare-const throttle_low_time Real)
(declare-const preglide_duration Real)
(declare-const sensor_detect_time Real)

; PreGlide must last at least 0.5 seconds
(assert (>= preglide_duration 0.5))

; Sensor must detect within preglide window
(assert (< sensor_detect_time (+ throttle_low_time preglide_duration)))
```

**Motor Control Constraints:**
```smt2
(declare-const motor_speed Int)
(declare-const throttle_pwm Int)

(assert (and (>= motor_speed 0) (<= motor_speed 255)))
(assert (and (>= throttle_pwm 900) (<= throttle_pwm 2000)))

; Motor stops only at low throttle or sensor detect
(assert (=> (= motor_speed 0)
            (or (<= throttle_pwm 950)
                (sensor_detected))))
```

### 8.3 Model Checking Workflow

#### Verification Process

```
1. Formalize requirements in temporal logic (TLA+)
2. Model system state machine
3. Specify invariants and properties
4. Run TLC model checker
5. Analyze counterexamples if found
6. Refine model or fix code
7. Re-verify
```

#### Safety Properties to Verify

1. **No Uncommanded Motor Start:**
   ```
   □(motor_state = "stopped" ∧ throttle < 950 => 
      ◇(motor_state = "stopped"))
   ```

2. **Sensor Detection Stops Motor:**
   ```
   □(sensor_detected => ◇(motor_state = "stopped"))
   ```

3. **Calibration Completes:**
   ```
   (mode = "calibration") ~> (mode = "normal")
   ```

4. **Timer Bounds:**
   ```
   □(timer >= 0 ∧ timer <= 200)
   ```

### 8.4 Integration into Development Workflow

#### CI/CD Pipeline Integration

```yaml
verification_stage:
  - name: TLA+ Model Check
    command: tlc GLDAB_System.tla
    expect: "No errors found"
  
  - name: Z3 Constraint Verification
    command: z3 constraints.smt2
    expect: "sat"
  
  - name: Generate Proof Certificate
    command: tlapm GLDAB_System.tla
```

#### Automated Invariant Testing

Generate test cases from model:
```
counterexample → regression test
property proved → assertion in code
```

---

## 9. Build System Modernization

### 9.1 PlatformIO Configuration

PlatformIO provides modern, cross-platform Arduino development.

#### Project Structure

```
NewGLDAB-by-Arduino/
├── platformio.ini
├── src/
│   ├── main.cpp (renamed from .ino)
│   ├── sensors/
│   │   ├── hall_sensor.h
│   │   ├── hall_sensor.cpp
│   │   ├── imu.h
│   │   └── imu.cpp
│   ├── control/
│   │   ├── quaternion.h
│   │   ├── quaternion.cpp
│   │   ├── pid_controller.h
│   │   └── pid_controller.cpp
│   └── utils/
│       ├── kalman_filter.h
│       └── kalman_filter.cpp
├── include/
│   └── config.h
├── lib/
│   └── (local libraries)
├── test/
│   ├── test_sensors/
│   ├── test_control/
│   └── test_quaternion/
└── docs/
```

#### platformio.ini Configuration

See: [`platformio.ini`](../../platformio.ini)

### 9.2 CMake Build System

#### CMakeLists.txt Structure

```cmake
cmake_minimum_required(VERSION 3.16)
project(NewGLDAB VERSION 1.0.0 LANGUAGES C CXX)

# Arduino toolchain
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/cmake/ArduinoToolchain.cmake)

# Target configuration
add_executable(NewGLDAB
    src/main.cpp
    src/sensors/hall_sensor.cpp
    src/sensors/imu.cpp
    src/control/quaternion.cpp
    src/control/pid_controller.cpp
)

target_include_directories(NewGLDAB PRIVATE include)
target_link_libraries(NewGLDAB PRIVATE arduino_core servo_lib)

# Testing
enable_testing()
add_subdirectory(test)
```

### 9.3 Dependency Management

#### Library Dependencies

```ini
[platformio]
lib_deps =
    ; Servo control
    arduino-libraries/Servo@^1.2.0
    
    ; IMU support
    adafruit/Adafruit MPU6050@^2.2.4
    adafruit/Adafruit Unified Sensor@^1.1.7
    
    ; Sensor support
    adafruit/Adafruit BMP3XX Library@^2.1.2
    adafruit/Adafruit SHT31 Library@^2.2.0
    
    ; Math libraries
    frankboesing/Quaternion@^1.0.0
    
    ; Testing
    throwtheswitch/Unity@^2.5.2
```

### 9.4 Continuous Integration

#### GitHub Actions Workflow

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up PlatformIO
        uses: platformio/platformio-action@v1
      
      - name: Build firmware
        run: pio run
      
      - name: Run tests
        run: pio test
      
      - name: Run TLA+ verification
        run: |
          sudo apt-get install -y tlaplus
          tlc docs/formal-verification/GLDAB_System.tla
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: firmware
          path: .pio/build/*/firmware.hex
```

### 9.5 Documentation Generation

#### Doxygen Configuration

```doxyfile
PROJECT_NAME           = "NewGLDAB"
PROJECT_BRIEF          = "Advanced Ornithopter Flight Control"
OUTPUT_DIRECTORY       = docs/api
EXTRACT_ALL            = YES
EXTRACT_PRIVATE        = YES
GENERATE_LATEX         = NO
GENERATE_HTML          = YES
RECURSIVE              = YES
INPUT                  = src include
```

---

## 10. Implementation Roadmap

### 10.1 Phase 1: Foundation (Weeks 1-4)

#### Objectives
- Modernize build system
- Establish testing framework
- Refactor existing code

#### Deliverables
1. PlatformIO project structure
2. Unit tests for current functionality
3. Modularized codebase
4. CI/CD pipeline

#### Success Criteria
- All existing functionality preserved
- Automated builds pass
- Test coverage > 80%

### 10.2 Phase 2: Sensor Integration (Weeks 5-8)

#### Objectives
- Integrate IMU (accelerometer, gyroscope, magnetometer)
- Add pressure and humidity sensors
- Implement sensor fusion

#### Deliverables
1. IMU driver and calibration routines
2. Kalman filter implementation
3. Quaternion-based orientation estimation
4. Sensor fusion test suite

#### Success Criteria
- Stable orientation estimation (< 1° error)
- Update rate > 100 Hz
- Successful hardware integration

### 10.3 Phase 3: Advanced Control (Weeks 9-12)

#### Objectives
- Implement quaternion-based control
- Add adaptive algorithms
- Enhance stability tracking

#### Deliverables
1. Quaternion rotation library
2. PID controller with auto-tuning
3. Disturbance rejection algorithms
4. Control system documentation

#### Success Criteria
- Improved stability in wind
- Faster convergence to glide position
- Adaptive parameter adjustment

### 10.4 Phase 4: Machine Learning (Weeks 13-16)

#### Objectives
- Develop lightweight ML models
- Implement situational awareness
- Create predictive algorithms

#### Deliverables
1. Trained MLP model (quantized for microcontroller)
2. Real-time inference engine
3. Flight mode classification
4. Performance evaluation report

#### Success Criteria
- Classification accuracy > 90%
- Inference time < 10 ms
- Successful flight tests

### 10.5 Phase 5: Formal Verification (Weeks 17-20)

#### Objectives
- Create TLA+ specifications
- Develop Z3 constraints
- Verify safety properties

#### Deliverables
1. Complete TLA+ model
2. Z3 constraint specifications
3. Verification report
4. Integration with CI/CD

#### Success Criteria
- All safety properties verified
- No counterexamples found
- Automated verification in pipeline

### 10.6 Phase 6: Integration and Testing (Weeks 21-24)

#### Objectives
- System integration
- Flight testing
- Performance optimization

#### Deliverables
1. Integrated system
2. Flight test results
3. Performance benchmarks
4. Final documentation

#### Success Criteria
- Successful autonomous flight
- Meets performance targets
- Comprehensive documentation

---

## 11. References and Bibliography

### 11.1 Aerodynamics and Fluid Mechanics

1. Anderson, J. D. (2017). *Fundamentals of Aerodynamics* (6th ed.). McGraw-Hill Education.

2. Shyy, W., Aono, H., Chimakurthi, S. K., Trizila, P., Kang, C. K., Cesnik, C. E., & Liu, H. (2010). Recent progress in flapping wing aerodynamics and aeroelasticity. *Progress in Aerospace Sciences*, 46(7), 284-327.

3. Mueller, T. J., & DeLaurier, J. D. (2003). Aerodynamics of small vehicles. *Annual Review of Fluid Mechanics*, 35(1), 89-111.

### 11.2 Materials Science

4. Ashby, M. F. (2011). *Materials Selection in Mechanical Design* (4th ed.). Butterworth-Heinemann.

5. Combes, S. A., & Daniel, T. L. (2003). Flexural stiffness in insect wings I. Scaling and the influence of wing venation. *Journal of Experimental Biology*, 206(17), 2979-2987.

### 11.3 Control Systems

6. Åström, K. J., & Murray, R. M. (2021). *Feedback Systems: An Introduction for Scientists and Engineers* (2nd ed.). Princeton University Press.

7. Mahony, R., Hamel, T., & Pflimlin, J. M. (2008). Nonlinear complementary filters on the special orthogonal group. *IEEE Transactions on Automatic Control*, 53(5), 1203-1218.

### 11.4 Quaternions and Spatial Mathematics

8. Kuipers, J. B. (1999). *Quaternions and Rotation Sequences: A Primer with Applications to Orbits, Aerospace, and Virtual Reality*. Princeton University Press.

9. Shoemake, K. (1985). Animating rotation with quaternion curves. *ACM SIGGRAPH Computer Graphics*, 19(3), 245-254.

10. Baez, J. C. (2002). The octonions. *Bulletin of the American Mathematical Society*, 39(2), 145-205.

### 11.5 Machine Learning

11. Goodfellow, I., Bengio, Y., & Courville, A. (2016). *Deep Learning*. MIT Press.

12. Raissi, M., Perdikaris, P., & Karniadakis, G. E. (2019). Physics-informed neural networks: A deep learning framework for solving forward and inverse problems involving nonlinear partial differential equations. *Journal of Computational Physics*, 378, 686-707.

### 11.6 Sensor Fusion and State Estimation

13. Kalman, R. E. (1960). A new approach to linear filtering and prediction problems. *Journal of Basic Engineering*, 82(1), 35-45.

14. Madgwick, S. O., Harrison, A. J., & Vaidyanathan, R. (2011). Estimation of IMU and MARG orientation using a gradient descent algorithm. *IEEE International Conference on Rehabilitation Robotics*.

### 11.7 Formal Verification

15. Lamport, L. (2002). *Specifying Systems: The TLA+ Language and Tools for Hardware and Software Engineers*. Addison-Wesley.

16. de Moura, L., & Bjørner, N. (2008). Z3: An efficient SMT solver. *International Conference on Tools and Algorithms for the Construction and Analysis of Systems*, 337-340.

### 11.8 Embedded Systems

17. Barrett, S. F., & Pack, D. J. (2012). *Arduino Microcontroller Processing for Everyone!* (3rd ed.). Morgan & Claypool Publishers.

18. Elecia White. (2011). *Making Embedded Systems: Design Patterns for Great Software*. O'Reilly Media.

### 11.9 Ornithopter Design

19. DeLaurier, J. D. (1993). An aerodynamic model for flapping-wing flight. *The Aeronautical Journal*, 97(964), 125-130.

20. Shkarayev, S., Costello, M., Krashantisa, R., & Houghton, J. (2008). *Introduction to the Design of Fixed-Wing Micro Air Vehicles*. AIAA.

---

## Appendices

### Appendix A: Glossary of Terms

**Debitum Technicum**: Technical debt; the implied cost of additional rework caused by choosing an easy solution now instead of using a better approach that would take longer.

**Lacunae**: Knowledge gaps; areas where understanding or documentation is incomplete or missing.

**Quaternion**: A four-dimensional number system used to represent 3D rotations without gimbal lock.

**Octonion**: An eight-dimensional normed division algebra extending quaternions to higher dimensions.

**MLP**: Multi-Layer Perceptron; a class of feedforward artificial neural network.

**TLA+**: Temporal Logic of Actions; a formal specification language for concurrent systems.

**Z3**: A satisfiability modulo theories (SMT) solver for constraint satisfaction.

**Hall Effect Sensor**: A transducer that varies its output voltage in response to a magnetic field.

**IMU**: Inertial Measurement Unit; device combining accelerometer, gyroscope, and often magnetometer.

**Kalman Filter**: An algorithm that uses a series of measurements observed over time to estimate unknown variables.

### Appendix B: Mathematical Notation

| Symbol | Meaning |
|--------|---------|
| ℝ | Set of real numbers |
| ∈ | Element of |
| ∖ | Set difference |
| Σ | Summation |
| ∂ | Partial derivative |
| ∇ | Gradient operator |
| ⊗ | Tensor/quaternion product |
| ‖·‖ | Norm (magnitude) |
| ·̂ | Unit vector |
| ·̇ | Time derivative |
| ·* | Complex/quaternion conjugate |
| ·ᵀ | Transpose |
| ~ | Proportional to |
| ≈ | Approximately equal |
| → | Maps to / implies |
| ◇ | Eventually (temporal logic) |
| □ | Always (temporal logic) |

### Appendix C: Contact Information

**Project Maintainer:**
- Name: Kazuhiko Kakuta
- Website: http://kakutaclinic.life.coocan.jp/
- YouTube: https://www.youtube.com/@BZH07614

**Research Collaboration:**
For questions regarding the research aspects of this report, please open an issue on the GitHub repository.

---

**Document History:**
- Version 1.0 (January 2026): Initial comprehensive research report

**License:**
This research document is released under the same license as the NewGLDAB project. See LICENSE file for details.

---

*End of Comprehensive Research Report*
