extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("FAIL: " + description)

func _run() -> void:
    _test_meters()
    await _test_scene()
    print("RESULT: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)

func _test_meters() -> void:
    var state := PetState.new()
    check(state.affection == 0.0 and state.happiness == 0.0, "meters start empty")
    state.advance(1.0, true)
    check(is_equal_approx(state.affection, 18.0), "one second of strokes adds 18 affection")
    check(state.happiness > 4.0, "happiness accrues during strokes")
    var low_rate := state.happiness_rate()
    state.advance(2.0, true)
    check(state.happiness_rate() > low_rate, "more affection accelerates happiness")
    var before_affection := state.affection
    var before_happiness := state.happiness
    state.advance(1.0, false)
    check(is_equal_approx(state.affection, before_affection), "idle grace retains affection")
    check(state.happiness > before_happiness, "happiness continues growing after releasing strokes")
    before_happiness = state.happiness
    state.advance(1.4, false)
    check(is_equal_approx(state.affection, before_affection - 3.5), "idle affection decays after grace")
    check(state.happiness > before_happiness, "happiness still grows while affection decays")
    var empty_affection := PetState.new()
    empty_affection.happiness = 30.0
    empty_affection.advance(2.4, false)
    check(is_equal_approx(empty_affection.happiness, 25.0), "happiness decays after grace when no affection remains")
    empty_affection.advance(20.0, false)
    check(empty_affection.happiness == 0.0 and empty_affection.happiness_rate() == 0.0, "empty affection produces no happiness")
    var lingering := PetState.new()
    lingering.affection = 80.0
    lingering.happiness = 99.99
    lingering.advance(0.01, false)
    check(lingering.celebrating, "residual affection can trigger celebration without petting")
    state.advance(100.0, false)
    check(state.affection == 0.0 and state.happiness == 0.0, "decay clamps at zero")
    state.advance(-1.0, true)
    check(state.affection == 0.0, "negative delta ignored")

    var joyful := PetState.new()
    joyful.affection = 76.0
    joyful.happiness = 99.9
    var events := [0, 0]
    joyful.celebration_started.connect(func(): events[0] += 1)
    joyful.celebration_finished.connect(func(): events[1] += 1)
    joyful.advance(0.02, true)
    check(joyful.celebrating and joyful.happiness == 100.0, "full meter triggers celebration")
    check(events[0] == 1, "celebration starts exactly once")
    var preserved_affection := joyful.affection
    joyful.advance(2.1, false)
    check(joyful.celebrating and joyful.happiness == 100.0, "full happiness held during animation")
    while joyful.celebrating:
        joyful.advance(1.0 / 60.0, false)
    check(not joyful.celebrating and joyful.happiness == 0.0, "animation finishes and happiness clears")
    check(is_equal_approx(joyful.affection, preserved_affection), "celebration preserves affection")
    check(events[1] == 1, "celebration finishes exactly once")
    joyful.advance(15.0, true)
    check(joyful.celebration_count >= 2, "celebration can repeat")
    check(joyful.affection <= 100.0 and joyful.happiness <= 100.0, "meters clamp at max")
    var slow := PetState.new()
    var fast := PetState.new()
    for i in range(60):
        slow.advance(1.0 / 15.0, true)
    for i in range(576):
        fast.advance(1.0 / 144.0, true)
    check(absf(slow.affection - fast.affection) < 0.01, "affection is frame-rate independent")
    check(absf(slow.happiness - fast.happiness) < 0.1, "happiness is stable across frame rates")

func _test_scene() -> void:
    var room = load("res://scenes/main.tscn").instantiate()
    root.add_child(room)
    room.set_process(false)
    room.player.set_physics_process(false)
    await process_frame
    await physics_frame
    check(room.hud.root.size.x >= 1280.0, "HUD root matches viewport width")
    check(room.hud.explore_button.get_global_rect().position.x > 0.0, "right anchored exploration button is on screen")
    check(room.hud.status_label.get_global_rect().position.y > 0.0, "bottom anchored controls are on screen")
    check(room.pet.presentation is NativePetPresentation, "native presenter loaded")
    check(room.pet.presentation.sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "pet always billboards toward camera")
    check(not room.can_interact(), "cannot interact from starting distance")
    room._open_interaction()
    check(not room.menu_open, "remote menu request rejected")
    room.player.position = Vector3(0, 0.02, 2.2)
    await physics_frame
    check(room.can_interact(), "close player facing pet can interact")
    var orientation: Vector3 = room.player.camera.global_rotation
    room.hud.interaction_requested.emit()
    check(room.menu_open and room.player.controls_enabled and room.player.interaction_active, "interaction menu keeps movement enabled")
    var menu_motion := InputEventMouseMotion.new()
    menu_motion.relative = Vector2(250, 170)
    room.player._unhandled_input(menu_motion)
    check(room.player.camera.global_rotation.is_equal_approx(orientation), "opening menu and moving cursor preserves camera orientation")
    room.player.set_physics_process(true)
    Input.action_press("move_left")
    for i in range(8):
        await physics_frame
    Input.action_release("move_left")
    room.player.set_physics_process(false)
    check(room.player.position.x < -0.15, "WASD moves during interaction with visible cursor")
    check(room.player.camera.global_rotation.is_equal_approx(orientation), "moving during interaction does not rotate view")
    room.player.position = Vector3(0, 0.02, 2.2)
    room.hud.stroke_pressed.emit()
    room._process(0.1)
    check(room.pet.state.affection > 0.0 and room.pet.is_stroking, "holding interaction button pets animal")
    room.hud.stroke_released.emit()
    room._process(0.1)
    check(not room.pet.is_stroking, "releasing button stops petting")
    var residual_happiness: float = room.pet.state.happiness
    room._process(0.1)
    check(room.pet.state.happiness > residual_happiness, "scene keeps generating happiness after button release")
    var affection: float = room.pet.state.affection
    room.hud.greeting_requested.emit()
    check(room.pet.presentation.greeting_remaining > 0.0, "greeting reaches presenter")
    check(room.pet.state.affection == affection, "greeting does not modify affection")
    room.pet.state.happiness = 99.99
    room.hud.stroke_pressed.emit()
    room._process(0.1)
    check(room.pet.presentation.joyful, "full happiness starts native happy animation")
    check(is_equal_approx(room.happiness_jar.fill_ratio, 1.0), "jar fills when happiness reaches maximum")
    var reset_event := [false]
    room.pet.state.celebration_finished.connect(func(): reset_event[0] = room.pet.state.happiness == 0.0)
    room.hud.stroke_released.emit()
    for i in range(24):
        room._process(0.1)
    check(not room.pet.presentation.joyful, "happy animation finishes")
    check(reset_event[0] and room.pet.state.affection > 0.0, "scene resets happiness at celebration end and retains affection")
    check(room.pet.state.happiness > 0.0 and room.pet.state.happiness < 5.0, "happiness resumes growing after celebration")
    check(is_equal_approx(room.happiness_jar.fill_ratio, room.pet.state.happiness / 100.0) and room.happiness_jar.fill_ratio < 0.05, "jar resets and tracks post-celebration happiness")
    _test_jar(room.happiness_jar)
    room.player.rotation.y = PI
    check(not room.can_interact(), "looking away disables interaction")
    room._process(0.1)
    check(not room.menu_open and not room.pointer_stroking and not room.player.interaction_active, "invalid interaction closes menu and releases stroke")
    room.player.rotation.y = 0.0
    var obstacle := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.5, 2.0, 0.2)
    collision.shape = shape
    obstacle.add_child(collision)
    obstacle.position = Vector3(0, 1, 1)
    room.add_child(obstacle)
    await physics_frame
    await physics_frame
    check(not room.can_interact(), "obstacle blocks interaction line of sight")
    obstacle.queue_free()
    await physics_frame
    await physics_frame
    room._open_interaction()
    room.hud.stroke_pressed.emit()
    room._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(not room.menu_open and not room.pointer_stroking, "focus loss cancels interactions")
    affection = room.pet.state.affection
    room._process(0.1)
    check(room.pet.state.affection == affection, "focus loss pauses simulation")
    room._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
    room.player.position = Vector3(0, 0.02, 2.2)
    room._open_interaction()
    room.hud.stroke_pressed.emit()
    room.player.position.z = 5.0
    room._process(0.1)
    check(not room.menu_open and not room.pet.is_stroking, "moving out of range cancels petting")
    check(room.hud.affection_bar.value >= 0.0, "HUD receives simulation values")
    if DisplayServer.get_name() != "headless":
        room.player.position = Vector3(0, 0.02, 2.2)
        room.player.controls_enabled = true
        room.player.set_physics_process(true)
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        Input.action_press("move_forward")
        for i in range(60):
            await physics_frame
        Input.action_release("move_forward")
        check(room.player.position.z < 1.5, "WASD input moves the player forward")
        check(room.player.position.z > 0.78, "pet footprint stops player walking through animal")
        check(absf(room.player.position.y) < 0.08, "floor collision supports player")
        var before_pitch: float = room.player.pitch
        var motion := InputEventMouseMotion.new()
        motion.relative = Vector2(100, 10000)
        room.player._unhandled_input(motion)
        check(room.player.rotation.y < 0.0, "mouse movement rotates first-person view")
        check(room.player.pitch < before_pitch and room.player.pitch >= -1.12, "vertical look is clamped")
    else:
        print("SKIP: 5 captured-mouse movement checks require a display (run without --headless).")
    room.queue_free()
    await process_frame
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _test_jar(jar: HappinessJar) -> void:
    jar.set_happiness(0.0)
    check(not jar.liquid.visible and not jar.surface.visible, "zero happiness hides all liquid")
    jar.set_happiness(50.0)
    check(jar.liquid.visible and is_equal_approx(jar.liquid.scale.y, HappinessJar.FILL_HEIGHT * 0.5), "half happiness fills half the jar")
    check(is_equal_approx(jar.liquid.position.y - jar.liquid.scale.y * 0.5, HappinessJar.FLOOR_Y), "liquid bottom stays on jar base")
    check(is_equal_approx(jar.surface.position.y, HappinessJar.FLOOR_Y + HappinessJar.FILL_HEIGHT * 0.5), "surface stays on top of liquid")
    jar.set_happiness(100.0)
    check(is_equal_approx(jar.liquid.scale.y, HappinessJar.FILL_HEIGHT), "full happiness fills to maximum height")
    jar.set_happiness(25.0)
    check(is_equal_approx(jar.liquid.scale.y, HappinessJar.FILL_HEIGHT * 0.25), "falling happiness lowers liquid volume")
    jar.set_happiness(-5.0)
    check(jar.fill_ratio == 0.0 and not jar.liquid.visible, "negative jar values clamp to empty")
    jar.set_happiness(130.0)
    check(jar.fill_ratio == 1.0, "jar values clamp to full")
    check(jar.get_node("GlassWall").mesh is CylinderMesh, "jar is real cylindrical geometry")
    check(jar.get_node("GlassWall").material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "glass material is transparent")
