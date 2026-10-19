class_name PetPresentation
extends Node3D
## Shared contract for native and Spine presenters. Never owns gameplay values.

func set_stroking(_active: bool) -> void:
    pass

func set_affection(_normalized: float) -> void:
    pass

func play_celebration() -> void:
    pass

func finish_celebration() -> void:
    pass

func play_greeting() -> void:
    pass
