class_name PetHUD
extends CanvasLayer

signal interaction_requested
signal greeting_requested
signal stroke_pressed
signal stroke_released
signal close_requested
signal explore_requested

const INK := Color("404d43")
const MUTED := Color("7b8375")
const PAPER := Color("fffaf0")
const GREEN := Color("6d9079")
const ORANGE := Color("cf9362")

var affection_bar: ProgressBar
var happiness_bar: ProgressBar
var affection_value: Label
var happiness_value: Label
var rate_label: Label
var mood_label: Label
var hint: Label
var interaction_panel: PanelContainer
var pet_button: Button
var greet_button: Button
var action_button: Button
var explore_button: Button
var celebration_banner: Label
var crosshair: Label
var status_label: Label
var speech_label: Label
var speech_seconds := 0.0
var root: Control

func _ready() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    root.size = get_viewport().get_visible_rect().size
    get_viewport().size_changed.connect(func(): root.size = get_viewport().get_visible_rect().size)
    var theme := Theme.new()
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["Noto Sans CJK TC", "Microsoft JhengHei", "PingFang TC", "sans-serif"])
    theme.default_font = font
    theme.default_font_size = 16
    root.theme = theme
    _build_header()
    _build_meters()
    _build_interactions()
    _build_footer()
    crosshair = _label("·", 32, Color(0.3, 0.37, 0.3, 0.7))
    root.add_child(crosshair)
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    _offset(crosshair, Vector2(-5, -24))
    celebration_banner = _label("好喜歡跟你在一起！", 25, INK)
    root.add_child(celebration_banner)
    celebration_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    _offset(celebration_banner, Vector2(-220, 132))
    celebration_banner.size.x = 440
    celebration_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    celebration_banner.hide()
    speech_label = _label("", 18, INK)
    root.add_child(speech_label)
    speech_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    _offset(speech_label, Vector2(-250, 170))
    speech_label.size.x = 500
    speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(delta: float) -> void:
    if speech_seconds > 0.0:
        speech_seconds -= delta
        if speech_seconds <= 0.0:
            speech_label.text = ""

func _build_header() -> void:
    var title := _label("MOMO", 38, INK)
    root.add_child(title)
    _offset(title, Vector2(38, 24))
    var subtitle := _label("小日子  /  一起慢慢長大", 14, MUTED)
    root.add_child(subtitle)
    _offset(subtitle, Vector2(40, 77))
    var room := _label("ROOM 01   /   晴日小屋\n3D 空間 × 2D 小夥伴", 14, MUTED)
    root.add_child(room)
    room.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _offset(room, Vector2(-290, 36))
    room.size.x = 250
    room.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _build_meters() -> void:
    var card := _panel(PAPER)
    root.add_child(card)
    card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _offset(card, Vector2(-322, 150))
    card.custom_minimum_size = Vector2(284, 0)
    var column := _column(card, 22)
    column.add_child(_label("YOUR LITTLE COMPANION", 11, MUTED))
    var name_row := HBoxContainer.new()
    column.add_child(name_row)
    var name_label := _label("毛毛", 28, INK)
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_row.add_child(name_label)
    name_row.add_child(_label("●  在家", 13, GREEN))
    mood_label = _label("正在等你靠近", 14, MUTED)
    column.add_child(mood_label)
    column.add_child(HSeparator.new())
    var affection_row := _meter(column, "撫摸度", GREEN)
    affection_bar = affection_row[0]
    affection_value = affection_row[1]
    column.add_child(_label("每一次溫柔，都會留下來。", 12, MUTED))
    var happiness_row := _meter(column, "快樂度", ORANGE)
    happiness_bar = happiness_row[0]
    happiness_value = happiness_row[1]
    rate_label = _label("持續累積  +0.0 快樂 / 秒", 12, MUTED)
    column.add_child(rate_label)
    column.add_child(HSeparator.new())
    column.add_child(_label("快樂滿格 → 開心小跳舞\n只歸零快樂，保留你的撫摸。", 13, MUTED))

func _build_interactions() -> void:
    interaction_panel = _panel(PAPER)
    root.add_child(interaction_panel)
    interaction_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _offset(interaction_panel, Vector2(-265, -230))
    interaction_panel.custom_minimum_size = Vector2(530, 0)
    var column := _column(interaction_panel, 20)
    column.add_child(_label("陪毛毛一下", 20, INK))
    column.add_child(_label("按住撫摸／空白鍵；WASD 可移動。", 14, MUTED))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    column.add_child(row)
    pet_button = _button("按住撫摸", GREEN, Color.WHITE)
    pet_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    pet_button.button_down.connect(func(): stroke_pressed.emit())
    pet_button.button_up.connect(func(): stroke_released.emit())
    row.add_child(pet_button)
    greet_button = _button("打招呼", Color("eee8d9"), INK)
    greet_button.pressed.connect(func(): greeting_requested.emit())
    row.add_child(greet_button)
    var close := _button("離開  E", Color("eee8d9"), INK)
    close.pressed.connect(func(): close_requested.emit())
    row.add_child(close)
    interaction_panel.hide()

func _build_footer() -> void:
    var note := _label("陪伴，不趕時間。", 23, INK)
    root.add_child(note)
    note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    _offset(note, Vector2(40, -135))
    var detail := _label("撫摸的餘溫，會繼續累積快樂。\n看看罐子裡的液面吧。", 13, MUTED)
    root.add_child(detail)
    detail.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    _offset(detail, Vector2(40, -94))
    hint = _label("向前走，靠近毛毛", 16, INK)
    root.add_child(hint)
    hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _offset(hint, Vector2(-230, -85))
    hint.size.x = 460
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    action_button = _button("E  ·  與毛毛互動", GREEN, Color.WHITE)
    root.add_child(action_button)
    action_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _offset(action_button, Vector2(-110, -126))
    action_button.custom_minimum_size = Vector2(220, 44)
    action_button.pressed.connect(func(): interaction_requested.emit())
    action_button.hide()
    explore_button = _button("點此探索小屋", GREEN, Color.WHITE)
    root.add_child(explore_button)
    explore_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    _offset(explore_button, Vector2(-242, -100))
    explore_button.custom_minimum_size = Vector2(204, 44)
    explore_button.pressed.connect(func(): explore_requested.emit())
    status_label = _label("W A S D  移動     滑鼠  環顧     E  互動     Esc  游標", 12, MUTED)
    root.add_child(status_label)
    status_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _offset(status_label, Vector2(-270, -36))
    status_label.size.x = 540
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func update_view(state: PetState, nearby: bool, menu_open: bool, stroking: bool, captured: bool) -> void:
    affection_bar.value = state.affection
    happiness_bar.value = state.happiness
    affection_value.text = "%02d / 100" % roundi(state.affection)
    happiness_value.text = "%02d / 100" % roundi(state.happiness)
    rate_label.text = "持續累積  +%.1f 快樂 / 秒" % state.happiness_rate()
    celebration_banner.visible = state.celebrating
    interaction_panel.visible = menu_open
    crosshair.visible = captured and not menu_open
    action_button.visible = nearby and not menu_open
    explore_button.visible = not captured and not menu_open
    pet_button.text = "好舒服呀…" if stroking else "按住撫摸"
    greet_button.disabled = state.celebrating
    if state.celebrating:
        mood_label.text = "開心到跳起來了！"
    elif stroking:
        mood_label.text = "瞇起眼睛，享受摸摸"
    elif state.affection > 60.0:
        mood_label.text = "好喜歡你，再陪我一下"
    elif nearby:
        mood_label.text = "牠正抬頭看著你"
    else:
        mood_label.text = "正在等你靠近"
    hint.visible = not menu_open
    if nearby:
        hint.text = "毛毛就在你面前"
    else:
        hint.text = "向前走、看向毛毛，即可互動"

func say(message: String) -> void:
    speech_label.text = message
    speech_seconds = 2.6

func _meter(parent: VBoxContainer, title: String, color: Color) -> Array:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var label := _label(title, 16, INK)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)
    var value := _label("00 / 100", 13, MUTED)
    row.add_child(value)
    var bar := ProgressBar.new()
    bar.custom_minimum_size.y = 10
    bar.show_percentage = false
    bar.add_theme_stylebox_override("background", _style(Color("eae8dc"), 5))
    bar.add_theme_stylebox_override("fill", _style(color, 5))
    parent.add_child(bar)
    return [bar, value]

func _label(text: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _style(color: Color, radius: int = 18) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    return style

func _panel(color: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    var style := _style(color)
    style.shadow_color = Color(0.25, 0.3, 0.23, 0.07)
    style.shadow_size = 12
    panel.add_theme_stylebox_override("panel", style)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return panel

func _column(parent: Control, margin: int) -> VBoxContainer:
    var inset := MarginContainer.new()
    for edge in ["left", "right", "top", "bottom"]:
        inset.add_theme_constant_override("margin_" + edge, margin)
    inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(inset)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inset.add_child(column)
    return column

func _button(text: String, color: Color, text_color: Color) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(100, 44)
    button.add_theme_color_override("font_color", text_color)
    button.add_theme_color_override("font_hover_color", text_color)
    button.add_theme_color_override("font_pressed_color", text_color)
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_stylebox_override("normal", _style(color, 10))
    button.add_theme_stylebox_override("hover", _style(color.lightened(0.07), 10))
    button.add_theme_stylebox_override("pressed", _style(color.darkened(0.1), 10))
    var focus := _style(Color.TRANSPARENT, 10)
    focus.border_color = ORANGE
    focus.set_border_width_all(2)
    button.add_theme_stylebox_override("focus", focus)
    return button

func _offset(control: Control, at: Vector2) -> void:
    # Offsets are relative to anchors; Control.position would be absolute here.
    var dimensions := control.size
    control.offset_left = at.x
    control.offset_top = at.y
    control.offset_right = at.x + dimensions.x
    control.offset_bottom = at.y + dimensions.y
