class_name PetState
extends RefCounted
## Simulation only. Values are independent of rendering, input, and Spine.
signal changed
signal celebration_started
signal celebration_finished

const MAX_VALUE := 100.0
const STROKE_GAIN := 18.0
const AFFECTION_DECAY := 3.5
const HAPPINESS_DECAY := 5.0
const IDLE_GRACE := 1.4
const CELEBRATION_DURATION := 2.2

var affection := 0.0
var happiness := 0.0
var celebrating := false
var celebration_count := 0
var idle_seconds := 0.0
var celebration_seconds := 0.0

func happiness_rate() -> float:
    if affection <= 0.0:
        return 0.0
    return 4.0 + 32.0 * pow(affection / MAX_VALUE, 1.6)

func advance(delta: float, stroking: bool) -> void:
    if delta <= 0.0:
        return
    # Integrate bounded slices so meter rates stay stable across frame rates.
    var remaining := delta
    while remaining > 0.000001:
        var step := minf(remaining, 1.0 / 60.0)
        _step(step, stroking)
        remaining -= step
    changed.emit()

func _step(delta: float, stroking: bool) -> void:
    if stroking:
        affection = minf(MAX_VALUE, affection + STROKE_GAIN * delta)
        idle_seconds = 0.0
    elif not celebrating:
        var previous_idle := idle_seconds
        idle_seconds += delta
        var decay_time := maxf(0.0, idle_seconds - IDLE_GRACE) - maxf(0.0, previous_idle - IDLE_GRACE)
        affection = maxf(0.0, affection - AFFECTION_DECAY * decay_time)
        if affection <= 0.0:
            happiness = maxf(0.0, happiness - HAPPINESS_DECAY * decay_time)

    if celebrating:
        celebration_seconds += delta
        if celebration_seconds >= CELEBRATION_DURATION:
            celebrating = false
            happiness = 0.0
            idle_seconds = 0.0
            celebration_finished.emit()
        return

    if affection > 0.0:
        happiness = minf(MAX_VALUE, happiness + happiness_rate() * delta)
        if happiness >= MAX_VALUE:
            celebrating = true
            celebration_seconds = 0.0
            celebration_count += 1
            celebration_started.emit()
