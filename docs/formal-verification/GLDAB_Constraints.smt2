; Z3 SMT Solver Constraint Specifications for NewGLDAB System
; 
; This file defines formal constraints for the ornithopter control system
; to verify safety properties, timing requirements, and physical constraints.
;
; Usage: z3 GLDAB_Constraints.smt2

(set-option :produce-models true)
(set-logic QF_UFNIRA)  ; Quantifier-Free Nonlinear Integer Real Arithmetic with Uninterpreted Functions

; ============================================================================
; SECTION 1: VARIABLE DECLARATIONS
; ============================================================================

; Wing state variables
(declare-const wing_angle Real)
(declare-const wing_velocity Real)
(declare-const optimal_glide_angle Real)

; Sensor variables
(declare-const sensor_threshold_low Real)
(declare-const sensor_threshold_high Real)
(declare-const magnet_strength Real)
(declare-const sensor_distance Real)

; Timing variables
(declare-const preglide_duration Real)
(declare-const throttle_low_time Real)
(declare-const sensor_detect_time Real)
(declare-const loop_iteration_time Real)
(declare-const max_preglide_time Real)

; Motor control variables
(declare-const motor_speed Int)
(declare-const throttle_pwm Int)
(declare-const preglide_motor_speed Int)

; System state flags
(declare-const sensor_detected Bool)
(declare-const motor_running Bool)
(declare-const preglide_active Bool)

; Physical constants
(declare-const air_density Real)
(declare-const lift_coefficient Real)
(declare-const drag_coefficient Real)
(declare-const wing_area Real)

; ============================================================================
; SECTION 2: DOMAIN CONSTRAINTS
; ============================================================================

; Wing angle must be in valid range [0, 360] degrees
(assert (and (>= wing_angle 0.0) (<= wing_angle 360.0)))
(assert (and (>= optimal_glide_angle 0.0) (<= optimal_glide_angle 360.0)))

; Wing velocity is bounded by physical limitations
(assert (and (>= wing_velocity -360.0) (<= wing_velocity 360.0)))

; Sensor thresholds (Hall effect sensor DN6852-A specifications)
(assert (= sensor_threshold_low 20.0))   ; 20 mT
(assert (= sensor_threshold_high 70.0))  ; 70 mT
(assert (and (>= magnet_strength 0.0) (<= magnet_strength 100.0)))

; Sensor detection distance (millimeters)
(assert (and (>= sensor_distance 0.0) (<= sensor_distance 10.0)))

; Timing constraints (seconds)
(assert (and (>= preglide_duration 0.0) (<= preglide_duration 2.0)))
(assert (and (>= loop_iteration_time 0.005) (<= loop_iteration_time 0.01)))
(assert (= max_preglide_time 1.0))

; PWM constraints (microseconds)
(assert (and (>= throttle_pwm 900) (<= throttle_pwm 2000)))
(assert (and (>= preglide_motor_speed 900) (<= preglide_motor_speed 2000)))

; Motor speed (0-255 for PWM)
(assert (and (>= motor_speed 0) (<= motor_speed 255)))

; Physical constants (SI units)
(assert (= air_density 1.225))  ; kg/m³ at sea level
(assert (and (>= lift_coefficient 0.0) (<= lift_coefficient 2.0)))
(assert (and (>= drag_coefficient 0.0) (<= drag_coefficient 0.5)))
(assert (and (>= wing_area 0.01) (<= wing_area 0.1)))  ; m²

; ============================================================================
; SECTION 3: SAFETY CONSTRAINTS
; ============================================================================

; SC1: Motor stops when sensor detects magnet
(assert (=> sensor_detected (= motor_speed 0)))

; SC2: Motor only runs if throttle is above minimum or in preglide mode
(assert (=> (> motor_speed 0)
            (or (> throttle_pwm 950) preglide_active)))

; SC3: Sensor detection occurs near optimal angle
(assert (=> sensor_detected
            (< (abs (- wing_angle optimal_glide_angle)) 10.0)))

; SC4: PreGlide mode requires low throttle
(assert (=> preglide_active (< throttle_pwm 950)))

; SC5: Motor speed matches throttle in normal operation
(assert (=> (and (not preglide_active) (> throttle_pwm 950))
            (> motor_speed 0)))

; SC6: PreGlide duration must be at least minimum
(assert (=> preglide_active
            (>= preglide_duration 0.5)))

; SC7: Sensor detection must occur within preglide window
(assert (=> sensor_detected
            (<= sensor_detect_time (+ throttle_low_time max_preglide_time))))

; ============================================================================
; SECTION 4: PHYSICAL CONSTRAINTS
; ============================================================================

; PC1: Magnetic field strength decreases with distance (inverse square law)
; B(r) = B₀ / (1 + r²)
(assert (=> (> sensor_distance 0.0)
            (< magnet_strength (/ 100.0 (+ 1.0 (* sensor_distance sensor_distance))))))

; PC2: Sensor detects when field strength in threshold range
(assert (= sensor_detected
           (and (>= magnet_strength sensor_threshold_low)
                (<= magnet_strength sensor_threshold_high))))

; PC3: Wing angle changes based on velocity and time
; θ(t) = θ₀ + ω·Δt
(assert (=> (> loop_iteration_time 0.0)
            (= wing_angle (+ optimal_glide_angle (* wing_velocity loop_iteration_time)))))

; PC4: Glide ratio constraint (L/D should be maximized)
; For optimal glide, typically L/D > 5 for ornithopters
(assert (> (/ lift_coefficient drag_coefficient) 5.0))

; PC5: Reynolds number for ornithopter scale
; Re = ρvL/μ, approximately 100,000 for typical ornithopter
; This affects lift and drag coefficients
(assert (and (>= lift_coefficient 0.8) (<= lift_coefficient 1.5)))
(assert (and (>= drag_coefficient 0.05) (<= drag_coefficient 0.15)))

; ============================================================================
; SECTION 5: TIMING CONSTRAINTS
; ============================================================================

; TC1: PreGlide must last between min and max duration
(assert (and (>= preglide_duration 0.5) (<= preglide_duration max_preglide_time)))

; TC2: Loop iteration time determines timer resolution
; timer_count = preglide_duration / loop_iteration_time
; For 140 iterations ≈ 1 second: loop_iteration_time ≈ 0.00714 s
(assert (=> (= preglide_duration 1.0)
            (< (abs (- loop_iteration_time 0.00714)) 0.001)))

; TC3: Sensor detection time ordering
(assert (< throttle_low_time sensor_detect_time))

; TC4: Total flight time considerations (battery life)
; Assuming 150 mAh battery and 30 mA average consumption = ~5 hours
; This is informational rather than a hard constraint

; ============================================================================
; SECTION 6: QUATERNION ROTATION CONSTRAINTS
; ============================================================================

; Quaternion representation: q = (w, x, y, z)
(declare-const q_w Real)
(declare-const q_x Real)
(declare-const q_y Real)
(declare-const q_z Real)

; QC1: Unit quaternion constraint: w² + x² + y² + z² = 1
(assert (= (+ (* q_w q_w) (* q_x q_x) (* q_y q_y) (* q_z q_z)) 1.0))

; QC2: Quaternion components are bounded
(assert (and (>= q_w -1.0) (<= q_w 1.0)))
(assert (and (>= q_x -1.0) (<= q_x 1.0)))
(assert (and (>= q_y -1.0) (<= q_y 1.0)))
(assert (and (>= q_z -1.0) (<= q_z 1.0)))

; QC3: Rotation angle from quaternion
; θ = 2·arccos(w)
(declare-const rotation_angle Real)
(assert (and (>= rotation_angle 0.0) (<= rotation_angle 6.2832)))  ; 0 to 2π

; ============================================================================
; SECTION 7: SENSOR FUSION CONSTRAINTS
; ============================================================================

; Complementary filter constraint
(declare-const alpha Real)
(declare-const angle_gyro Real)
(declare-const angle_accel Real)
(declare-const angle_fused Real)

; SFC1: Alpha is filter coefficient [0.9, 0.99]
(assert (and (>= alpha 0.9) (<= alpha 0.99)))

; SFC2: Fused angle combines gyro and accelerometer
; θ_fused = α·θ_gyro + (1-α)·θ_accel
(assert (= angle_fused (+ (* alpha angle_gyro) (* (- 1.0 alpha) angle_accel))))

; SFC3: All angles in valid range
(assert (and (>= angle_gyro 0.0) (<= angle_gyro 360.0)))
(assert (and (>= angle_accel 0.0) (<= angle_accel 360.0)))
(assert (and (>= angle_fused 0.0) (<= angle_fused 360.0)))

; ============================================================================
; SECTION 8: STABILITY CONSTRAINTS
; ============================================================================

(declare-const angular_acceleration Real)
(declare-const stability_index Real)

; STC1: Stability index based on angular acceleration
; SI = exp(-||ω̇||²/σ²), σ = 10 rad/s²
(assert (and (>= stability_index 0.0) (<= stability_index 1.0)))

; STC2: Low angular acceleration means high stability
(assert (=> (< (abs angular_acceleration) 5.0)
            (> stability_index 0.8)))

; STC3: High angular acceleration means low stability
(assert (=> (> (abs angular_acceleration) 20.0)
            (< stability_index 0.5)))

; ============================================================================
; SECTION 9: OPTIMIZATION OBJECTIVES
; ============================================================================

; OO1: Minimize time to reach optimal glide angle
; This is a soft constraint - the system should converge quickly
(declare-const convergence_time Real)
(assert (and (>= convergence_time 0.0) (<= convergence_time 2.0)))

; OO2: Maximize glide ratio (L/D)
; Already constrained by PC4, but we want it as large as possible
(assert (>= (/ lift_coefficient drag_coefficient) 8.0))

; OO3: Minimize power consumption in glide mode
(assert (=> (not motor_running) (= motor_speed 0)))

; ============================================================================
; SECTION 10: TEST SCENARIOS
; ============================================================================

; Define several test scenarios to verify

; Scenario 1: Normal PreGlide operation
(push)
(assert (= throttle_pwm 900))
(assert preglide_active)
(assert (= preglide_duration 1.0))
(assert (not sensor_detected))
(check-sat)
; (get-model)
(pop)

; Scenario 2: Sensor detection stops motor
(push)
(assert sensor_detected)
(assert (= motor_speed 0))
(assert (< (abs (- wing_angle optimal_glide_angle)) 5.0))
(check-sat)
; (get-model)
(pop)

; Scenario 3: Optimal glide configuration
(push)
(assert (= wing_angle optimal_glide_angle))
(assert (not motor_running))
(assert (> (/ lift_coefficient drag_coefficient) 10.0))
(assert (> stability_index 0.9))
(check-sat)
; (get-model)
(pop)

; Scenario 4: Quaternion rotation validity
(push)
(assert (= (+ (* q_w q_w) (* q_x q_x) (* q_y q_y) (* q_z q_z)) 1.0))
(assert (> q_w 0.707))  ; Rotation < 90 degrees
(check-sat)
; (get-model)
(pop)

; ============================================================================
; SECTION 11: MAIN VERIFICATION QUERY
; ============================================================================

; Verify that all constraints are satisfiable
(check-sat)

; If satisfiable, get a model showing valid parameter values
(get-model)

; Additional queries to verify specific properties
(echo "Checking safety property: sensor detection stops motor")
(push)
(assert sensor_detected)
(assert (> motor_speed 0))
(check-sat)  ; Should be UNSAT (contradicts safety constraint)
(pop)

(echo "Checking liveness: preglide eventually completes")
(push)
(assert preglide_active)
(assert (>= preglide_duration max_preglide_time))
(assert (not sensor_detected))
(check-sat)  ; Should be SAT (timeout case is valid)
(pop)

(echo "Checking optimal glide conditions")
(push)
(assert (= wing_angle optimal_glide_angle))
(assert (= motor_speed 0))
(assert (> stability_index 0.8))
(assert (> (/ lift_coefficient drag_coefficient) 8.0))
(check-sat)  ; Should be SAT
(pop)

(exit)
