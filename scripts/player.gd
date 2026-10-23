class_name FirstPersonPlayer
extends CharacterBody3D

const SPEED := 3.0
const MOUSE_SENSITIVITY := 0.0023
var camera: Camera3D
var controls_enabled := true
var interaction_active := false
var focused := true
var pitch := -0.15

func _ready() -> void:
    for action in {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D}:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            var key := InputEventKey.new()
            key.physical_keycode = {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D}[action]
            InputMap.action_add_event(action, key)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.24
    capsule.height = 1.7
    collision.shape = capsule
    collision.position.y = 0.85
    add_child(collision)
    camera = Camera3D.new()
    camera.position.y = 1.58
    camera.rotation.x = pitch
    camera.fov = 65.0
    camera.near = 0.05
    camera.current = true
    add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and controls_enabled and focused and not interaction_active and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        pitch = clampf(pitch - event.relative.y * MOUSE_SENSITIVITY, -1.12, 1.12)
        camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
    var movement := Vector2.ZERO
    if controls_enabled and focused and (interaction_active or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
        movement = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := transform.basis * Vector3(movement.x, 0.0, movement.y)
    velocity.x = direction.x * SPEED
    velocity.z = direction.z * SPEED
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
