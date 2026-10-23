class_name HappinessJar
extends Node3D
## A real 3D glass vessel. Liquid volume is linear in happiness (0–100).
const INNER_RADIUS := 0.405
const FLOOR_Y := 0.12
const FILL_HEIGHT := 1.12
const GLASS_HEIGHT := 1.4
var liquid: MeshInstance3D
var surface: MeshInstance3D
var value_label: Label3D
var fill_ratio := 0.0

func _ready() -> void:
    var glass := StandardMaterial3D.new()
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.albedo_color = Color(0.77, 0.94, 0.91, 0.17)
    glass.cull_mode = BaseMaterial3D.CULL_DISABLED
    glass.roughness = 0.15
    glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    var wall := CylinderMesh.new()
    wall.top_radius = 0.46
    wall.bottom_radius = 0.46
    wall.height = GLASS_HEIGHT
    wall.radial_segments = 64
    wall.cap_top = false
    wall.cap_bottom = false
    _mesh("GlassWall", wall, glass, Vector3(0, GLASS_HEIGHT * 0.5 + 0.04, 0))
    var rim_material := _material(Color("9bbdb2"))
    for y in [0.08, GLASS_HEIGHT + 0.04]:
        var rim := TorusMesh.new()
        rim.inner_radius = 0.425
        rim.outer_radius = 0.485
        rim.rings = 48
        rim.ring_segments = 12
        _mesh("GlassRim", rim, rim_material, Vector3(0, y, 0))
    var base := CylinderMesh.new()
    base.top_radius = 0.455
    base.bottom_radius = 0.455
    base.height = 0.06
    base.radial_segments = 64
    _mesh("GlassBase", base, glass, Vector3(0, 0.03, 0))
    var fluid_mesh := CylinderMesh.new()
    fluid_mesh.top_radius = INNER_RADIUS
    fluid_mesh.bottom_radius = INNER_RADIUS
    fluid_mesh.height = 1.0
    fluid_mesh.radial_segments = 64
    liquid = _mesh("HappinessLiquid", fluid_mesh, _material(Color("df9a54")), Vector3.ZERO)
    var top_mesh := CylinderMesh.new()
    top_mesh.top_radius = INNER_RADIUS
    top_mesh.bottom_radius = INNER_RADIUS
    top_mesh.height = 0.008
    top_mesh.radial_segments = 64
    surface = _mesh("LiquidSurface", top_mesh, _material(Color("ffce81")), Vector3.ZERO)
    # Fine graduation marks on the front of the vessel.
    for i in range(5):
        var tick := BoxMesh.new()
        tick.size = Vector3(0.12 if i % 2 == 0 else 0.07, 0.014, 0.012)
        _mesh("Graduation", tick, rim_material, Vector3(0.0, FLOOR_Y + FILL_HEIGHT * i / 4.0, 0.463))
    # A narrow side highlight gives the glass a readable outline when empty.
    var highlight := BoxMesh.new()
    highlight.size = Vector3(0.018, 1.05, 0.012)
    _mesh("GlassHighlight", highlight, _material(Color("e5eee0")), Vector3(-0.30, 0.74, 0.35))
    value_label = Label3D.new()
    value_label.position.y = 1.67
    value_label.font_size = 32
    value_label.pixel_size = 0.0027
    value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    value_label.modulate = Color("647f6b")
    value_label.outline_size = 0
    add_child(value_label)
    var body := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = 0.485
    shape.height = GLASS_HEIGHT + 0.06
    collision.shape = shape
    collision.position.y = shape.height * 0.5
    body.add_child(collision)
    add_child(body)
    set_happiness(fill_ratio * 100.0)

func set_happiness(value: float) -> void:
    fill_ratio = clampf(value / 100.0, 0.0, 1.0)
    if not is_instance_valid(liquid):
        return
    var height := FILL_HEIGHT * fill_ratio
    liquid.visible = fill_ratio > 0.0
    surface.visible = liquid.visible
    # Keep the bottom fixed to the base, rather than scaling around the center.
    liquid.scale.y = maxf(height, 0.0001)
    liquid.position.y = FLOOR_Y + height * 0.5
    surface.position.y = FLOOR_Y + height
    value_label.text = "HAPPINESS  %03d%%" % roundi(fill_ratio * 100.0)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.4
    return material

func _mesh(node_name: String, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    instance.mesh = mesh
    instance.material_override = material
    instance.position = at
    add_child(instance)
    return instance
