# Quaternion Mathematics for Flight Control

## Overview

This document details the mathematical foundations of quaternion-based 3D rotation for ornithopter flight control, providing a gimbal-lock-free alternative to Euler angles.

## 1. Quaternion Fundamentals

### 1.1 Definition

A quaternion is a four-dimensional extension of complex numbers:

```
q = w + xi + yj + zk
```

Where:
- `w, x, y, z ∈ ℝ` (real numbers)
- `i² = j² = k² = ijk = -1` (fundamental quaternion relations)

### 1.2 Quaternion Properties

**Norm (Magnitude):**
```
||q|| = √(w² + x² + y² + z²)
```

**Unit Quaternion:**
For rotation representation, use unit quaternions where `||q|| = 1`

**Conjugate:**
```
q* = w - xi - yj - zk
```

**Inverse:**
```
q⁻¹ = q*/||q||²
```

For unit quaternions: `q⁻¹ = q*`

## 2. Rotation Representation

### 2.1 Axis-Angle to Quaternion

Given a rotation axis `n̂ = (n_x, n_y, n_z)` (unit vector) and angle `θ`:

```
q = (cos(θ/2), sin(θ/2)·n_x, sin(θ/2)·n_y, sin(θ/2)·n_z)
```

Or in vector form:
```
q = (cos(θ/2), sin(θ/2)·n̂)
```

### 2.2 Quaternion to Axis-Angle

Given unit quaternion `q = (w, x, y, z)`:

```
θ = 2·arccos(w)
n̂ = (x, y, z)/sin(θ/2)
```

Special case: if `w = 1` (no rotation), `θ = 0` and axis is undefined.

### 2.3 Euler Angles to Quaternion

Given Euler angles (roll `φ`, pitch `θ`, yaw `ψ`):

```
q_w = cos(φ/2)cos(θ/2)cos(ψ/2) + sin(φ/2)sin(θ/2)sin(ψ/2)
q_x = sin(φ/2)cos(θ/2)cos(ψ/2) - cos(φ/2)sin(θ/2)sin(ψ/2)
q_y = cos(φ/2)sin(θ/2)cos(ψ/2) + sin(φ/2)cos(θ/2)sin(ψ/2)
q_z = cos(φ/2)cos(θ/2)sin(ψ/2) - sin(φ/2)sin(θ/2)cos(ψ/2)
```

### 2.4 Quaternion to Euler Angles

```
φ (roll)  = atan2(2(q_w·q_x + q_y·q_z), 1 - 2(q_x² + q_y²))
θ (pitch) = asin(2(q_w·q_y - q_z·q_x))
ψ (yaw)   = atan2(2(q_w·q_z + q_x·q_y), 1 - 2(q_y² + q_z²))
```

## 3. Quaternion Operations

### 3.1 Multiplication (Composition)

To compose rotations `q₁` followed by `q₂`:

```
q = q₂ ⊗ q₁
```

Quaternion multiplication formula:
```
q₂ ⊗ q₁ = (w₂w₁ - x₂x₁ - y₂y₁ - z₂z₁,
           w₂x₁ + x₂w₁ + y₂z₁ - z₂y₁,
           w₂y₁ - x₂z₁ + y₂w₁ + z₂x₁,
           w₂z₁ + x₂y₁ - y₂x₁ + z₂w₁)
```

**Note:** Quaternion multiplication is NOT commutative: `q₂ ⊗ q₁ ≠ q₁ ⊗ q₂`

### 3.2 Rotating a Vector

To rotate vector `v = (v_x, v_y, v_z)` by quaternion `q`:

1. Represent vector as pure quaternion: `v_q = (0, v_x, v_y, v_z)`
2. Apply rotation: `v'_q = q ⊗ v_q ⊗ q*`
3. Extract rotated vector: `v' = (v'_x, v'_y, v'_z)` from `v'_q`

**Optimized formula** (avoiding quaternion multiplications):
```
v' = v + 2w(q⃗ × v) + 2(q⃗ × (q⃗ × v))
```

Where `q⃗ = (x, y, z)` is the vector part of quaternion `q = (w, x, y, z)`

### 3.3 Inverse Rotation

To apply inverse rotation:
```
v'_q = q* ⊗ v_q ⊗ q
```

## 4. Quaternion Interpolation

### 4.1 Linear Interpolation (LERP)

Simple but not constant velocity:
```
q(t) = (1-t)q₀ + t·q₁
q(t) = q(t)/||q(t)||  (normalize result)
```

### 4.2 Spherical Linear Interpolation (SLERP)

Provides constant angular velocity interpolation:

```
q(t) = (sin((1-t)Ω)/sin(Ω))q₀ + (sin(t·Ω)/sin(Ω))q₁
```

Where:
```
cos(Ω) = q₀·q₁ = w₀w₁ + x₀x₁ + y₀y₁ + z₀z₁
```

**Special cases:**
- If `cos(Ω) < 0`, negate one quaternion to take shorter path
- If `|cos(Ω)| ≈ 1`, use LERP (quaternions are very close)

## 5. Integration with Angular Velocity

### 5.1 Quaternion Differential Equation

Given angular velocity `ω = (ω_x, ω_y, ω_z)`:

```
dq/dt = (1/2)·Ω(ω)·q
```

Where `Ω(ω)` is the skew-symmetric matrix:

```
Ω(ω) = [ 0    -ω_x  -ω_y  -ω_z ]
       [ ω_x    0    ω_z  -ω_y ]
       [ ω_y  -ω_z    0    ω_x ]
       [ ω_z   ω_y  -ω_x    0  ]
```

### 5.2 Euler Integration

Simple first-order integration:

```
q(t+Δt) = q(t) + (Δt/2)·Ω(ω(t))·q(t)
q(t+Δt) = q(t+Δt)/||q(t+Δt)||  (renormalize)
```

### 5.3 Runge-Kutta 4th Order (RK4)

More accurate integration:

```
k₁ = (Δt/2)·Ω(ω(t))·q(t)
k₂ = (Δt/2)·Ω(ω(t + Δt/2))·(q(t) + k₁/2)
k₃ = (Δt/2)·Ω(ω(t + Δt/2))·(q(t) + k₂/2)
k₄ = (Δt/2)·Ω(ω(t + Δt))·(q(t) + k₃)

q(t+Δt) = q(t) + (k₁ + 2k₂ + 2k₃ + k₄)/6
q(t+Δt) = q(t+Δt)/||q(t+Δt)||
```

## 6. Conversion to Rotation Matrix

For interfacing with graphics or other systems:

```
R = [ 1-2(y²+z²)   2(xy-wz)     2(xz+wy)   ]
    [ 2(xy+wz)     1-2(x²+z²)   2(yz-wx)   ]
    [ 2(xz-wy)     2(yz+wx)     1-2(x²+y²) ]
```

## 7. Practical Implementation

### 7.1 C++ Quaternion Class

```cpp
class Quaternion {
public:
    float w, x, y, z;
    
    Quaternion(float w=1, float x=0, float y=0, float z=0) 
        : w(w), x(x), y(y), z(z) {}
    
    // Normalize to unit quaternion
    void normalize() {
        float norm = sqrt(w*w + x*x + y*y + z*z);
        if (norm > 1e-6) {
            w /= norm; x /= norm; y /= norm; z /= norm;
        }
    }
    
    // Quaternion multiplication
    Quaternion operator*(const Quaternion& q) const {
        return Quaternion(
            w*q.w - x*q.x - y*q.y - z*q.z,
            w*q.x + x*q.w + y*q.z - z*q.y,
            w*q.y - x*q.z + y*q.w + z*q.x,
            w*q.z + x*q.y - y*q.x + z*q.w
        );
    }
    
    // Conjugate
    Quaternion conjugate() const {
        return Quaternion(w, -x, -y, -z);
    }
    
    // Rotate a vector
    void rotate(float& vx, float& vy, float& vz) const {
        // Using optimized formula
        float qx = x, qy = y, qz = z, qw = w;
        
        // t = 2 * cross(q.xyz, v)
        float tx = 2 * (qy*vz - qz*vy);
        float ty = 2 * (qz*vx - qx*vz);
        float tz = 2 * (qx*vy - qy*vx);
        
        // v' = v + w*t + cross(q.xyz, t)
        vx += qw*tx + (qy*tz - qz*ty);
        vy += qw*ty + (qz*tx - qx*tz);
        vz += qw*tz + (qx*ty - qy*tx);
    }
    
    // Convert from axis-angle
    static Quaternion fromAxisAngle(float nx, float ny, float nz, float angle) {
        float half_angle = angle * 0.5f;
        float s = sin(half_angle);
        return Quaternion(cos(half_angle), nx*s, ny*s, nz*s);
    }
    
    // Convert to Euler angles (radians)
    void toEuler(float& roll, float& pitch, float& yaw) const {
        roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y));
        pitch = asin(2*(w*y - z*x));
        yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z));
    }
};
```

### 7.2 Integration Example

```cpp
// Update quaternion from gyroscope readings
void updateQuaternion(Quaternion& q, float wx, float wy, float wz, float dt) {
    // Create quaternion from angular velocity
    float half_dt = dt * 0.5f;
    Quaternion dq(0, wx*half_dt, wy*half_dt, wz*half_dt);
    
    // Update: q = q + dq * q
    q = q + (dq * q);
    q.normalize();
}
```

## 8. Advantages Over Euler Angles

1. **No Gimbal Lock**: No singularities at any orientation
2. **Smooth Interpolation**: SLERP provides constant angular velocity
3. **Compact**: 4 values vs 9 for rotation matrix
4. **Efficient**: Fewer operations than matrix math
5. **Stable**: Better numerical properties for integration

## 9. Common Pitfalls

1. **Forgetting to normalize**: Always normalize after operations
2. **Double coverage**: `q` and `-q` represent same rotation
3. **Multiplication order**: `q₂ ⊗ q₁` means `q₁` first, then `q₂`
4. **Integration drift**: Renormalize periodically to maintain unit norm

## 10. References

1. Kuipers, J. B. (1999). *Quaternions and Rotation Sequences*
2. Shoemake, K. (1985). "Animating rotation with quaternion curves"
3. Diebel, J. (2006). "Representing Attitude: Euler Angles, Unit Quaternions, and Rotation Vectors"

## 11. Application to NewGLDAB

For the ornithopter control system:

1. **Orientation Estimation**: Use quaternions to track body orientation from IMU
2. **Wing Angle Control**: Represent target wing orientation as quaternion
3. **Smooth Transitions**: SLERP for smooth movement to glide position
4. **Sensor Fusion**: Combine gyroscope and accelerometer using quaternions
5. **Stability Analysis**: Compute angular deviations using quaternion difference

### Example: Wing Position Control

```cpp
// Target glide orientation
Quaternion target = Quaternion::fromAxisAngle(0, 1, 0, glide_angle);

// Current wing orientation (from sensors)
Quaternion current = getCurrentOrientation();

// Compute shortest rotation to target
Quaternion error = target * current.conjugate();

// Extract rotation axis and angle for control
float angle;
float axis_x, axis_y, axis_z;
error.toAxisAngle(axis_x, axis_y, axis_z, angle);

// Control command proportional to error angle
float motor_command = Kp * angle;
```

---

*This document is part of the NewGLDAB Comprehensive Research Report*
