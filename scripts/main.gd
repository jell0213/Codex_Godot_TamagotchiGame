extends Node3D
## The room orchestrates input and simulation; the presenter only draws the pet.
@export var pet_presentation_scene: PackedScene

const INTERACTION_DISTANCE := 2.8
var player: FirstPersonPlayer
var pet: PetActor
var hud: PetHUD
var menu_open := false
var pointer_stroking := false
var nearby := false
var focused := true
var greeting_cooldown := 0.0

func _ready() -> void:
    _build_room()
    pet = PetActor.new()
    pet.presentation_scene = pet_presentation_scene
    pet.name = "Momo"
    pet.position = Vector3(0.0, 0.9, 0.0)
    add_child(pet)
    player = FirstPersonPlayer.new()
    player.name = "Player"
    player.position = Vector3(0.0, 0.02, 4.3)
    add_child(player)
    hud = PetHUD.new()
    add_child(hud)
    hud.interaction_requested.connect(_open_interaction)
    hud.close_requested.connect(_close_interaction)
    hud.explore_requested.connect(_capture_mouse)
    hud.greeting_requested.connect(_greet)
    hud.stroke_pressed.connect(func(): pointer_stroking = true)
    hud.stroke_released.connect(func(): pointer_stroking = false)
    pet.state.celebration_started.connect(func(): hud.say("毛毛：今天也是被愛著的一天。"))
    # Begin with a visible cursor so the player can read the controls first.
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var nameplate := Label3D.new()
    nameplate.text = "M O M O"
    nameplate.font_size = 36
    nameplate.pixel_size = 0.003
    nameplate.modulate = Color("657765")
    nameplate.outline_size = 0
    nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    nameplate.position = Vector3(0, 2.1, 0)
    add_child(nameplate)

func _process(delta: float) -> void:
    nearby = can_interact()
    if menu_open and not nearby:
        _close_interaction()
    greeting_cooldown = maxf(0.0, greeting_cooldown - delta)
    # Limit a resumed frame's simulation time; losing focus never pets the animal.
    var stroking := focused and menu_open and nearby and (pointer_stroking or Input.is_physical_key_pressed(KEY_SPACE))
    if focused:
        pet.simulate(minf(delta, 0.1), stroking)
    hud.update_view(pet.state, nearby, menu_open, stroking, Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)

func can_interact() -> bool:
    if not is_instance_valid(player) or not is_instance_valid(pet):
        return false
    var planar := Vector2(player.global_position.x - pet.global_position.x, player.global_position.z - pet.global_position.z)
    if planar.length() > INTERACTION_DISTANCE:
        return false
    var to_pet := pet.global_position - player.camera.global_position
    var camera_forward := -player.camera.global_transform.basis.z
    if camera_forward.dot(to_pet.normalized()) < 0.65:
        return false
    var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, pet.global_position)
    query.exclude = [player.get_rid()]
    # The pet uses a footprint collider; the ray targets above it.
    return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_E:
            if menu_open:
                _close_interaction()
            elif can_interact():
                _open_interaction()
        elif event.physical_keycode == KEY_ESCAPE:
            pointer_stroking = false
            if menu_open:
                _close_interaction(false)
            elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            else:
                _capture_mouse()
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        pointer_stroking = false

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        focused = false
        pointer_stroking = false
        menu_open = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        if is_instance_valid(player):
            player.focused = false
            player.controls_enabled = true
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        focused = true
        if is_instance_valid(player):
            player.focused = true

func _capture_mouse() -> void:
    if not menu_open:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _open_interaction() -> void:
    if not can_interact():
        return
    menu_open = true
    pointer_stroking = false
    player.controls_enabled = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_interaction(capture: bool = true) -> void:
    menu_open = false
    pointer_stroking = false
    player.controls_enabled = true
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE

func _greet() -> void:
    if menu_open and can_interact() and greeting_cooldown <= 0.0 and not pet.state.celebrating:
        pet.greet()
        hud.say("啾！毛毛搖搖身體，向你說你好。")
        greeting_cooldown = 1.5

func _build_room() -> void:
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color("e9eddd")
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color("fff1da")
    settings.ambient_light_energy = 0.85
    settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    environment.environment = settings
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_color = Color("fff3d9")
    sun.light_energy = 0.6
    add_child(sun)
    _box(Vector3(0, -0.12, 1), Vector3(12, 0.2, 12), Color("e6e1d0"), true, SpriteFactory.floor_texture())
    _box(Vector3(0, 1.6, -5), Vector3(12, 3.4, 0.2), Color("d9e0cd"), true)
    _box(Vector3(-6, 1.6, 1), Vector3(0.2, 3.4, 12), Color("e5e4d4"), true)
    _box(Vector3(6, 1.6, 1), Vector3(0.2, 3.4, 12), Color("e5e4d4"), true)
    _box(Vector3(0, 1.6, 7), Vector3(12, 3.4, 0.2), Color("e5e4d4"), true)
    _box(Vector3(0, 0.15, -4.86), Vector3(12, 0.28, 0.08), Color("a6b59a"))
    # A fixed wall window belongs to the background, so it never billboards.
    _box(Vector3(-2.6, 2.1, -4.85), Vector3(2.4, 1.7, 0.08), Color("faf4e2"))
    _box(Vector3(-2.6, 2.1, -4.78), Vector3(2.12, 1.42, 0.05), Color("b5c9bd"))
    _box(Vector3(-2.6, 2.1, -4.73), Vector3(0.08, 1.45, 0.04), Color("faf4e2"))
    _box(Vector3(-2.6, 2.1, -4.72), Vector3(2.15, 0.08, 0.04), Color("faf4e2"))
    _box(Vector3(-2.6, 1.18, -4.7), Vector3(2.65, 0.12, 0.35), Color("d3b692"))
    _box(Vector3(2.2, 2.0, -4.83), Vector3(1.3, 1.65, 0.1), Color("b89c76"))
    _box(Vector3(2.2, 2.0, -4.75), Vector3(1.15, 1.5, 0.04), Color("f5eedc"))
    var poster := Label3D.new()
    poster.text = "little\ndays."
    poster.font_size = 86
    poster.pixel_size = 0.004
    poster.modulate = Color("79937c")
    poster.outline_size = 0
    poster.position = Vector3(2.2, 2.05, -4.69)
    add_child(poster)
    _ground_decal(SpriteFactory.rug(), Vector3(0, 0.005, 0), 3.3)
    _ground_decal(SpriteFactory.shadow(), Vector3(0, 0.013, 0), 1.35)
    _prop(SpriteFactory.plant(), Vector3(-2.7, 0.96, -2.4), 2.1)
    _prop(SpriteFactory.plant(), Vector3(3.2, 0.8, -3.5), 1.75)
    _prop(SpriteFactory.cushion(), Vector3(2.1, 0.65, -0.8), 1.6)
    # Low invisible footprint colliders prevent walking through flat decorations.
    _footprint(Vector3(0, 0.2, 0), 0.58, 0.4)
    _footprint(Vector3(-2.7, 0.3, -2.4), 0.36, 0.6)
    _footprint(Vector3(3.2, 0.3, -3.5), 0.32, 0.6)
    _footprint(Vector3(2.1, 0.16, -0.8), 0.6, 0.32)

func _box(at: Vector3, dimensions: Vector3, color: Color, solid: bool = false, texture: Texture2D = null) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = dimensions
    mesh.mesh = box
    mesh.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    if texture:
        material.albedo_color = Color.WHITE
        material.albedo_texture = texture
        material.uv1_scale = Vector3(8, 8, 8)
    material.roughness = 1.0
    mesh.material_override = material
    add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collider.shape = shape
        body.position = at
        body.add_child(collider)
        add_child(body)

func _prop(texture: Texture2D, at: Vector3, height: float) -> void:
    var sprite := Sprite3D.new()
    sprite.texture = texture
    sprite.position = at
    sprite.pixel_size = height / texture.get_height()
    sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(sprite)

func _ground_decal(texture: Texture2D, at: Vector3, width: float) -> void:
    var sprite := Sprite3D.new()
    sprite.texture = texture
    sprite.position = at
    sprite.pixel_size = width / texture.get_width()
    sprite.rotation_degrees.x = -90
    add_child(sprite)

func _footprint(at: Vector3, radius: float, height: float) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = radius
    shape.height = height
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
