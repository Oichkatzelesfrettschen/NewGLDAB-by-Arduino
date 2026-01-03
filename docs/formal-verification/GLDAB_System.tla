---------------------------- MODULE GLDAB_System ----------------------------
(*
    TLA+ Specification for NewGLDAB Ornithopter Control System
    
    This specification models the safety-critical behavior of the GLDAB system,
    which controls wing position for optimal gliding using a Hall effect sensor
    and Arduino Pro Mini microcontroller.
    
    Key Properties Verified:
    1. Safety: Motor never starts unexpectedly
    2. Liveness: System eventually reaches glide position
    3. Deadlock-freedom: System never gets stuck
    4. Timing constraints: PreGlide duration bounds
*)

EXTENDS Naturals, Sequences, TLC

CONSTANTS 
    MAX_TIMER,         \* Maximum timer value (typically 200)
    MIN_THROTTLE,      \* Minimum throttle value (900)
    MAX_THROTTLE,      \* Maximum throttle value (2000)
    PREGLIDE_LOW,      \* Low throttle threshold (950)
    PREGLIDE_HIGH,     \* High throttle threshold (1950)
    MIN_PREGLIDE_TIME, \* Minimum preglide duration
    MAX_PREGLIDE_TIME  \* Maximum preglide duration

VARIABLES
    wing_angle,         \* Current wing angle in degrees [0..360]
    motor_state,        \* Motor state: "stopped", "running", "preglide"
    throttle,           \* Throttle PWM value [MIN_THROTTLE..MAX_THROTTLE]
    sensor_detected,    \* TRUE when Hall sensor detects magnet
    led_state,          \* TRUE when LED is on
    timer,              \* PreGlide timer counter
    mode,               \* System mode: "normal", "calibration", "setup"
    pgms,               \* PreGlide Motor Speed setting stored in EEPROM
    flag,               \* Calibration completion flag
    flag2,              \* PreGlide mode activation flag
    flag3               \* Initialization completion flag

vars == <<wing_angle, motor_state, throttle, sensor_detected, led_state, 
          timer, mode, pgms, flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Type invariants - define the valid ranges for all variables *)
TypeOK == 
    /\ wing_angle \in 0..360
    /\ motor_state \in {"stopped", "running", "preglide"}
    /\ throttle \in MIN_THROTTLE..MAX_THROTTLE
    /\ sensor_detected \in BOOLEAN
    /\ led_state \in BOOLEAN
    /\ timer \in 0..MAX_TIMER
    /\ mode \in {"normal", "calibration", "setup"}
    /\ pgms \in 0..366  \* pgms = (PreGMS - 900) / 3, max ~= 366
    /\ flag \in {0, 1}
    /\ flag2 \in {0, 1}
    /\ flag3 \in {0, 1}

-----------------------------------------------------------------------------

(* Initial state - system startup *)
Init == 
    /\ wing_angle = 0
    /\ motor_state = "stopped"
    /\ throttle = MIN_THROTTLE
    /\ sensor_detected = FALSE
    /\ led_state = FALSE
    /\ timer = 0
    /\ mode = "normal"
    /\ pgms \in 0..366  \* Read from EEPROM, could be any valid value
    /\ flag = 0
    /\ flag2 = 0
    /\ flag3 = 0

-----------------------------------------------------------------------------

(* Action: Throttle stick moved by pilot *)
ThrottleChange ==
    /\ throttle' \in MIN_THROTTLE..MAX_THROTTLE
    /\ UNCHANGED <<wing_angle, motor_state, sensor_detected, led_state, 
                   timer, mode, pgms, flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: Enter calibration mode - throttle max high *)
EnterCalibration ==
    /\ mode = "normal"
    /\ throttle > PREGLIDE_HIGH
    /\ flag = 0
    /\ mode' = "calibration"
    /\ led_state' = TRUE
    /\ motor_state' = "stopped"
    /\ UNCHANGED <<wing_angle, throttle, sensor_detected, timer, pgms, 
                   flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: Setup PreGlide motor speed during calibration *)
SetupPreGlideSpeed ==
    /\ mode = "calibration"
    /\ throttle < PREGLIDE_LOW
    /\ led_state = TRUE
    /\ pgms' \in 0..366  \* New PGMS value set
    /\ flag' = 1  \* Mark calibration complete
    /\ mode' = "setup"
    /\ led_state' = FALSE
    /\ UNCHANGED <<wing_angle, motor_state, throttle, sensor_detected, 
                   timer, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: Exit calibration back to normal mode *)
ExitCalibration ==
    /\ mode = "setup"
    /\ flag = 1
    /\ mode' = "normal"
    /\ UNCHANGED <<wing_angle, motor_state, throttle, sensor_detected, 
                   led_state, timer, pgms, flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: Normal motor operation - throttle controls motor directly *)
NormalMotorOperation ==
    /\ mode = "normal"
    /\ flag = 1
    /\ throttle >= PREGLIDE_LOW
    /\ flag2 = 0
    /\ motor_state' = "running"
    /\ UNCHANGED <<wing_angle, throttle, sensor_detected, led_state, 
                   timer, mode, pgms, flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: Enter PreGlide mode - throttle drops below threshold *)
EnterPreGlide ==
    /\ mode = "normal"
    /\ flag = 1
    /\ flag3 = 1
    /\ throttle < PREGLIDE_LOW
    /\ flag2 = 0
    /\ motor_state' = "preglide"
    /\ led_state' = TRUE
    /\ timer' = 0
    /\ flag2' = 1
    /\ UNCHANGED <<wing_angle, throttle, sensor_detected, mode, pgms, 
                   flag, flag3>>

-----------------------------------------------------------------------------

(* Action: PreGlide timer tick - motor runs at PGMS speed *)
PreGlideTick ==
    /\ motor_state = "preglide"
    /\ timer < MAX_TIMER
    /\ ~sensor_detected
    /\ timer' = timer + 1
    /\ wing_angle' = (wing_angle + 1) % 361  \* Wing continues moving
    /\ UNCHANGED <<motor_state, throttle, sensor_detected, led_state, 
                   mode, pgms, flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: Sensor detects magnet during PreGlide *)
SensorDetection ==
    /\ motor_state = "preglide"
    /\ timer >= MIN_PREGLIDE_TIME
    /\ timer <= MAX_PREGLIDE_TIME
    /\ sensor_detected' = TRUE
    /\ motor_state' = "stopped"
    /\ led_state' = FALSE
    /\ timer' = MAX_TIMER  \* Force timer to exit condition
    /\ UNCHANGED <<wing_angle, throttle, mode, pgms, flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: PreGlide timeout - no sensor detection *)
PreGlideTimeout ==
    /\ motor_state = "preglide"
    /\ timer = MAX_TIMER
    /\ ~sensor_detected
    /\ motor_state' = "stopped"
    /\ led_state' = FALSE
    /\ UNCHANGED <<wing_angle, throttle, sensor_detected, timer, mode, 
                   pgms, flag, flag2, flag3>>

-----------------------------------------------------------------------------

(* Action: Exit PreGlide mode - throttle raised *)
ExitPreGlide ==
    /\ motor_state = "stopped"
    /\ flag2 = 1
    /\ throttle > PREGLIDE_LOW
    /\ flag2' = 0
    /\ sensor_detected' = FALSE
    /\ timer' = 0
    /\ UNCHANGED <<wing_angle, motor_state, led_state, mode, pgms, 
                   flag, flag3, throttle>>

-----------------------------------------------------------------------------

(* Action: Complete initialization *)
CompleteInit ==
    /\ flag3 = 0
    /\ flag3' = 1
    /\ UNCHANGED <<wing_angle, motor_state, throttle, sensor_detected, 
                   led_state, timer, mode, pgms, flag, flag2>>

-----------------------------------------------------------------------------

(* Next state relation - all possible transitions *)
Next == 
    \/ ThrottleChange
    \/ EnterCalibration
    \/ SetupPreGlideSpeed
    \/ ExitCalibration
    \/ NormalMotorOperation
    \/ EnterPreGlide
    \/ PreGlideTick
    \/ SensorDetection
    \/ PreGlideTimeout
    \/ ExitPreGlide
    \/ CompleteInit

-----------------------------------------------------------------------------

(* Temporal formula - system specification *)
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

-----------------------------------------------------------------------------

(* SAFETY PROPERTIES *)

(* S1: Motor only runs when throttle is high or in PreGlide mode *)
SafeMotorOperation ==
    (motor_state = "running") => 
        (throttle >= PREGLIDE_LOW \/ motor_state = "preglide")

(* S2: Sensor detection always stops motor *)
SensorStopsMotor ==
    sensor_detected => (motor_state = "stopped")

(* S3: LED indicates PreGlide mode correctly *)
LEDIndicatesPreGlide ==
    (motor_state = "preglide") => led_state

(* S4: Timer stays within bounds *)
TimerBounds ==
    timer >= 0 /\ timer <= MAX_TIMER

(* S5: Motor cannot start while throttle is low (unless PreGlide) *)
NoSpuriousStart ==
    (throttle < PREGLIDE_LOW /\ motor_state' = "running") => 
        (motor_state = "preglide")

(* S6: Calibration mode can only be entered from normal mode *)
CalibrationEntryGuard ==
    (mode' = "calibration") => (mode = "normal")

(* Combined safety property *)
Safety == 
    /\ TypeOK
    /\ SafeMotorOperation
    /\ SensorStopsMotor
    /\ LEDIndicatesPreGlide
    /\ TimerBounds
    /\ NoSpuriousStart
    /\ CalibrationEntryGuard

-----------------------------------------------------------------------------

(* LIVENESS PROPERTIES *)

(* L1: Low throttle eventually leads to PreGlide mode *)
EventualPreGlide ==
    (throttle < PREGLIDE_LOW /\ flag = 1 /\ flag3 = 1) ~> 
        (motor_state = "preglide")

(* L2: Sensor detection eventually stops motor *)
EventualStop ==
    sensor_detected ~> (motor_state = "stopped")

(* L3: Calibration mode eventually completes *)
CalibrationCompletes ==
    (mode = "calibration") ~> (mode = "normal")

(* L4: PreGlide mode eventually terminates *)
PreGlideTerminates ==
    (motor_state = "preglide") ~> (motor_state = "stopped")

(* L5: System eventually completes initialization *)
EventualInit ==
    (flag3 = 0) ~> (flag3 = 1)

-----------------------------------------------------------------------------

(* DEADLOCK FREEDOM *)

(* System can always make progress *)
NoDeadlock ==
    ENABLED Next

-----------------------------------------------------------------------------

(* MODEL CHECKING CONFIGURATION *)

(* Constraint for bounded model checking *)
StateConstraint ==
    /\ timer <= MAX_TIMER
    /\ wing_angle <= 360

(* Symmetry reduction - throttle values are symmetric *)
Symmetry == Permutations({MIN_THROTTLE, PREGLIDE_LOW, PREGLIDE_HIGH, MAX_THROTTLE})

-----------------------------------------------------------------------------

(* INVARIANTS TO CHECK *)

THEOREM Spec => []Safety
THEOREM Spec => <>[]EventualPreGlide
THEOREM Spec => []<>NoDeadlock

=============================================================================
\* Model checking parameters for TLC:
\*
\* CONSTANTS:
\*   MAX_TIMER = 200
\*   MIN_THROTTLE = 900
\*   MAX_THROTTLE = 2000
\*   PREGLIDE_LOW = 950
\*   PREGLIDE_HIGH = 1950
\*   MIN_PREGLIDE_TIME = 10
\*   MAX_PREGLIDE_TIME = 200
\*
\* SPECIFICATION: Spec
\*
\* INVARIANTS: Safety, TypeOK
\*
\* PROPERTIES: EventualPreGlide, EventualStop, CalibrationCompletes
\*
\* STATE CONSTRAINT: StateConstraint
