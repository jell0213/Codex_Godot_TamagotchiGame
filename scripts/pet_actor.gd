class_name PetActor
extends Node3D
## Set presentation_scene to a scene rooted at PetPresentation to replace visuals.
@export var presentation_scene: PackedScene
var state := PetState.new()
var presentation: PetPresentation
var is_stroking := false

func _ready() -> void:
    if presentation_scene:
        var instance := presentation_scene.instantiate()
        if instance is PetPresentation:
            presentation = instance
        else:
            instance.free()
            push_error("Pet presentation scene must extend PetPresentation; using native fallback.")
    if not presentation:
        presentation = NativePetPresentation.new()
    add_child(presentation)
    state.celebration_started.connect(presentation.play_celebration)
    state.celebration_finished.connect(presentation.finish_celebration)

func simulate(delta: float, stroking: bool) -> void:
    is_stroking = stroking
    state.advance(delta, stroking)
    presentation.set_stroking(stroking)
    presentation.set_affection(state.affection / PetState.MAX_VALUE)

func greet() -> void:
    presentation.play_greeting()
