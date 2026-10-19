class_name NativePetPresentation
extends PetPresentation

var sprite: Sprite3D
var textures: Dictionary = {}
var stroking := false
var joyful := false
var affection := 0.0
var clock := 0.0
var greeting_remaining := 0.0
var heart_clock := 0.0

func _ready() -> void:
    for expression in ["idle", "blink", "pet", "happy"]:
        textures[expression] = SpriteFactory.pet(expression)
    sprite = Sprite3D.new()
    sprite.texture = textures.idle
    sprite.pixel_size = 0.007
    sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sprite.no_depth_test = false
    sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
    sprite.shaded = false
    add_child(sprite)

func _process(delta: float) -> void:
    clock += delta
    greeting_remaining = maxf(0.0, greeting_remaining - delta)
    var bounce := sin(clock * 2.6) * 0.025
    var squash := 1.0
    if joyful:
        bounce = absf(sin(clock * 10.0)) * 0.36
        squash = 1.0 + sin(clock * 10.0) * 0.07
        sprite.texture = textures.happy
        heart_clock -= delta
        if heart_clock <= 0.0:
            _heart()
            heart_clock = 0.18
    elif stroking:
        bounce = sin(clock * 8.0) * 0.025
        squash = 1.0 + sin(clock * 6.0) * 0.035
        sprite.texture = textures.pet
    elif greeting_remaining > 0.0:
        bounce = absf(sin(clock * 9.0)) * 0.12
        sprite.texture = textures.happy
    else:
        sprite.texture = textures.blink if fmod(clock, 4.6) > 4.42 else textures.idle
    sprite.position.y = bounce
    sprite.scale = Vector3(1.0 / squash, squash, 1.0)
    sprite.rotation.z = sin(clock * (8.0 if joyful else 2.0)) * (0.09 if joyful else 0.018)

func set_stroking(active: bool) -> void:
    stroking = active

func set_affection(normalized: float) -> void:
    affection = normalized

func play_celebration() -> void:
    joyful = true
    heart_clock = 0.0

func finish_celebration() -> void:
    joyful = false

func play_greeting() -> void:
    greeting_remaining = 1.2

func _heart() -> void:
    var particle := Sprite3D.new()
    particle.texture = SpriteFactory.heart()
    particle.pixel_size = 0.005
    particle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    particle.position = Vector3(randf_range(-0.65, 0.65), 0.7, 0.02)
    particle.modulate.a = 0.85
    add_child(particle)
    var tween := create_tween().set_parallel(true)
    tween.tween_property(particle, "position:y", particle.position.y + 0.9, 1.1).set_trans(Tween.TRANS_SINE)
    tween.tween_property(particle, "modulate:a", 0.0, 1.1)
    tween.chain().tween_callback(particle.queue_free)
