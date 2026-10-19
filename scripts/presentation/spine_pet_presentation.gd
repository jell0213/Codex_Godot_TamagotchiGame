class_name SpinePetPresentation
extends PetPresentation
## Optional adapter: Godot does not import Spine skeletons without a compatible runtime.
## Render any runtime's Node2D scene into a billboard without coupling game logic to it.
@export var spine_scene: PackedScene
@export var canvas_size := Vector2i(512, 512)
@export var skeleton_origin := Vector2(256, 440)
@export var world_pixel_size := 0.0035
@export var idle_animation := "idle"
@export var stroke_animation := "pet"
@export var happy_animation := "happy"
@export var greeting_animation := "greet"

var driver: Node
var active_animation := ""
var stroking := false
var celebrating := false
var greeting_left := 0.0

func _ready() -> void:
    if not spine_scene:
        push_error("Assign a Spine runtime scene to spine_scene before using this adapter.")
        return
    var viewport := SubViewport.new()
    viewport.size = canvas_size
    viewport.transparent_bg = true
    viewport.disable_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(viewport)
    var origin := Node2D.new()
    origin.position = skeleton_origin
    viewport.add_child(origin)
    driver = spine_scene.instantiate()
    origin.add_child(driver)
    if not driver.has_method("play_pet_animation"):
        push_error("Spine scene root must implement play_pet_animation(name: String, loop: bool).")
    var billboard := Sprite3D.new()
    billboard.texture = viewport.get_texture()
    billboard.pixel_size = world_pixel_size
    billboard.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(billboard)
    _refresh()

func _process(delta: float) -> void:
    if greeting_left > 0.0:
        greeting_left = maxf(0.0, greeting_left - delta)
        if greeting_left == 0.0:
            _refresh()

func set_stroking(active: bool) -> void:
    if stroking != active:
        stroking = active
        _refresh()

func set_affection(normalized: float) -> void:
    if is_instance_valid(driver) and driver.has_method("set_pet_parameters"):
        driver.call("set_pet_parameters", {"affection": normalized, "stroking": stroking, "celebrating": celebrating})

func play_celebration() -> void:
    celebrating = true
    _refresh()

func finish_celebration() -> void:
    celebrating = false
    _refresh()

func play_greeting() -> void:
    greeting_left = 1.2
    _refresh()

func _refresh() -> void:
    var requested := idle_animation
    if celebrating:
        requested = happy_animation
    elif stroking:
        requested = stroke_animation
    elif greeting_left > 0.0:
        requested = greeting_animation
    if requested != active_animation and is_instance_valid(driver) and driver.has_method("play_pet_animation"):
        active_animation = requested
        driver.call("play_pet_animation", requested, requested == idle_animation or requested == stroke_animation)
