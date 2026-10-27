class_name GameHUD extends CanvasLayer

@export var drag_raycast: RayCast3D

# UI Nodes
@onready var root_control: Control = $RootControl
@onready var reticle_node: Control = $RootControl/Reticle
@onready var info_card: PanelContainer = $RootControl/InfoCard
@onready var item_title_label: Label = $RootControl/InfoCard/MarginContainer/VBox/HeaderRow/Title
@onready var item_badge_label: Label = $RootControl/InfoCard/MarginContainer/VBox/HeaderRow/Badge
@onready var action_prompt_label: Label = $RootControl/InfoCard/MarginContainer/VBox/ActionPrompt
@onready var distance_label: Label = $RootControl/InfoCard/MarginContainer/VBox/DistanceLabel

# State
var current_target: Node = null
var current_distance: float = -1.0
var is_in_range: bool = false
var is_holding: bool = false
var held_object: Node = null
var target_cup: Node = null

var zoom_distance: float = 1.0
var zoom_min: float = 0.5
var zoom_max: float = 1.65
var zoom_display_timer: float = 0.0

# Animation variables
var anim_bracket_radius: float = 24.0
var anim_bracket_alpha: float = 0.0
var anim_center_radius: float = 3.5
var anim_card_alpha: float = 0.0
var pulse_clock: float = 0.0

# Platform detection
var has_touch: bool = false

func _ready() -> void:
	layer = 10
	has_touch = DisplayServer.is_touchscreen_available()
	_find_and_connect_raycast()
	_setup_card_style()

func _find_and_connect_raycast() -> void:
	if not drag_raycast:
		# Check relative path in Player scene
		drag_raycast = get_node_or_null("../Camera/DragRaycast")
		if not drag_raycast:
			drag_raycast = get_node_or_null("../../Camera/DragRaycast")

	if drag_raycast:
		if not drag_raycast.target_changed.is_connected(_on_target_changed):
			drag_raycast.target_changed.connect(_on_target_changed)
		if not drag_raycast.drag_started.is_connected(_on_drag_started):
			drag_raycast.drag_started.connect(_on_drag_started)
		if not drag_raycast.drag_stopped.is_connected(_on_drag_stopped):
			drag_raycast.drag_stopped.connect(_on_drag_stopped)
		if not drag_raycast.drag_distance_changed.is_connected(_on_drag_distance_changed):
			drag_raycast.drag_distance_changed.connect(_on_drag_distance_changed)
		if not drag_raycast.pour_target_changed.is_connected(_on_pour_target_changed):
			drag_raycast.pour_target_changed.connect(_on_pour_target_changed)

func _setup_card_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.05, 0.88)
	style.border_color = Color(0.92, 0.68, 0.25, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	info_card.add_theme_stylebox_override("panel", style)
	info_card.modulate.a = 0.0

func _process(delta: float) -> void:
	pulse_clock += delta * 4.0
	if zoom_display_timer > 0.0:
		zoom_display_timer -= delta

	_update_animations(delta)
	_update_card_content()
	reticle_node.queue_redraw()

func _update_animations(delta: float) -> void:
	var target_bracket_radius = 24.0
	var target_bracket_alpha = 0.0
	var target_center_radius = 3.5
	var target_card_alpha = 0.0

	if is_holding:
		target_bracket_radius = 18.0
		target_bracket_alpha = 1.0
		target_center_radius = 4.5
		target_card_alpha = 1.0
	elif is_instance_valid(current_target):
		target_card_alpha = 1.0
		if is_in_range:
			target_bracket_radius = 15.0 + sin(pulse_clock) * 1.5
			target_bracket_alpha = 1.0
			target_center_radius = 4.5
		else:
			target_bracket_radius = 20.0
			target_bracket_alpha = 0.45
			target_center_radius = 3.0
	else:
		target_bracket_radius = 26.0
		target_bracket_alpha = 0.0
		target_center_radius = 3.0
		target_card_alpha = 0.0

	anim_bracket_radius = lerp(anim_bracket_radius, target_bracket_radius, delta * 12.0)
	anim_bracket_alpha = lerp(anim_bracket_alpha, target_bracket_alpha, delta * 10.0)
	anim_center_radius = lerp(anim_center_radius, target_center_radius, delta * 14.0)
	anim_card_alpha = lerp(anim_card_alpha, target_card_alpha, delta * 10.0)

	info_card.modulate.a = anim_card_alpha

func _update_card_content() -> void:
	if anim_card_alpha < 0.05:
		return

	if is_holding and is_instance_valid(held_object):
		_display_holding_card()
	elif is_instance_valid(current_target):
		_display_target_card()

func _display_target_card() -> void:
	var item_name = "Object"
	var item_status = ""
	var is_pourable_item = false

	if current_target.has_method("get_display_name"):
		item_name = current_target.get_display_name()
	else:
		item_name = current_target.name.capitalize()

	if current_target.has_method("get_status_text"):
		item_status = current_target.get_status_text()

	if current_target.has_method("is_pourable"):
		is_pourable_item = current_target.is_pourable()

	# Icon prefix
	var icon = "📦"
	var lower = item_name.to_lower()
	if lower.contains("milk"):
		icon = "🥛"
	elif lower.contains("coffee"):
		icon = "☕"
	elif lower.contains("caramel") or lower.contains("vanilla") or lower.contains("syrup"):
		icon = "🍯"
	elif lower.contains("sugar"):
		icon = "🧂"
	elif lower.contains("donut") or lower.contains("pastry"):
		icon = "🍩"
	elif lower.contains("cup"):
		icon = "🍵"

	item_title_label.text = icon + "  " + item_name
	item_badge_label.text = ("[" + item_status + "]") if item_status != "" else ""

	if is_in_range:
		var interact_cue = "Touch & Hold to Grab" if has_touch else "[Hold Click] Grab & Move"
		action_prompt_label.text = interact_cue
		action_prompt_label.modulate = Color(0.98, 0.85, 0.45)
		distance_label.text = "• In Reach (" + ("%.1f" % current_distance) + "m)"
		distance_label.modulate = Color(0.45, 0.95, 0.55)
	else:
		action_prompt_label.text = "Out of reach — Step closer"
		action_prompt_label.modulate = Color(0.85, 0.55, 0.45)
		distance_label.text = "• Too Far (" + ("%.1f" % current_distance) + "m / Max 2.0m)"
		distance_label.modulate = Color(0.95, 0.45, 0.45)

func _display_holding_card() -> void:
	var item_name = "Held Item"
	var item_status = ""
	var is_pourable_item = false

	if held_object.has_method("get_display_name"):
		item_name = held_object.get_display_name()
	else:
		item_name = held_object.name.capitalize()

	if held_object.has_method("get_status_text"):
		item_status = held_object.get_status_text()

	if held_object.has_method("is_pourable"):
		is_pourable_item = held_object.is_pourable()

	item_title_label.text = "✋  Holding: " + item_name
	item_badge_label.text = ("[" + item_status + "]") if item_status != "" else ""

	var drop_cue = "Release Touch to Drop" if has_touch else "[Release Click] Drop"
	var prompt = drop_cue + "  •  [Scroll] Reach"

	if is_pourable_item:
		if is_instance_valid(target_cup):
			prompt = "[Hold Right Click] POUR INTO CUP! ☕"
			action_prompt_label.modulate = Color(0.35, 0.95, 0.6)
		else:
			prompt = "[Hold Right Click] Pour Milk  •  " + drop_cue + " Drop"
			action_prompt_label.modulate = Color(0.4, 0.85, 1.0)
	elif is_instance_valid(target_cup) and item_name.to_lower().contains("coffee"):
		prompt = drop_cue + " Drop into Cup to add Coffee!"
		action_prompt_label.modulate = Color(0.35, 0.95, 0.6)
	else:
		action_prompt_label.modulate = Color(0.4, 0.85, 1.0)

	action_prompt_label.text = prompt
	distance_label.text = "• Reach: " + ("%.1f" % zoom_distance) + "m"
	distance_label.modulate = Color(0.7, 0.85, 1.0)

# SIGNAL CALLBACKS

func _on_target_changed(target: Node, distance: float, in_range: bool) -> void:
	current_target = target
	current_distance = distance
	is_in_range = in_range

func _on_drag_started(item: Node) -> void:
	is_holding = true
	held_object = item
	target_cup = null

func _on_drag_stopped(_item: Node) -> void:
	is_holding = false
	held_object = null
	target_cup = null

func _on_drag_distance_changed(distance: float, min_dist: float, max_dist: float) -> void:
	zoom_distance = distance
	zoom_min = min_dist
	zoom_max = max_dist
	zoom_display_timer = 2.0

func _on_pour_target_changed(cup: Node) -> void:
	target_cup = cup

# PROCEDURAL RETICLE DRAWING (Called on ReticleControl)

func draw_reticle(control: Control) -> void:
	var center = control.size / 2.0

	var core_color: Color
	var border_color: Color = Color(0.08, 0.08, 0.08, 0.75)

	if is_holding:
		if is_instance_valid(target_cup):
			core_color = Color(0.3, 0.95, 0.6, 1.0) # Emerald pour target
		else:
			core_color = Color(0.35, 0.82, 1.0, 1.0) # Cyan holding
	elif is_instance_valid(current_target):
		if is_in_range:
			core_color = Color(0.96, 0.72, 0.22, 1.0) # Barista gold
		else:
			core_color = Color(0.75, 0.6, 0.45, 0.65) # Out of range amber-gray
	else:
		core_color = Color(1.0, 0.98, 0.95, 0.8) # Idle cream white

	# 1. Dark outer shadow ring for center dot (guarantees visibility on any backdrop)
	control.draw_circle(center, anim_center_radius + 1.2, border_color)
	# 2. Crisp center dot
	control.draw_circle(center, anim_center_radius, core_color)

	# 3. Draw In-Range / Target Brackets or Out-of-Range Ring
	if anim_bracket_alpha > 0.01:
		var bracket_color = core_color
		bracket_color.a = anim_bracket_alpha

		if is_holding:
			_draw_holding_reticle(control, center, anim_bracket_radius, bracket_color)
		elif is_in_range:
			_draw_brackets(control, center, anim_bracket_radius, bracket_color)
		else:
			_draw_out_of_range_ring(control, center, anim_bracket_radius, bracket_color)

	# 4. Zoom / Reach slider indicator while dragging
	if is_holding and zoom_display_timer > 0.0:
		_draw_zoom_slider(control, center)

func _draw_brackets(control: Control, center: Vector2, r: float, color: Color) -> void:
	var arm = 5.0
	var w = 2.0
	var dark = Color(0.05, 0.05, 0.05, color.a * 0.7)

	# 4 Corner brackets: Top-Left, Top-Right, Bottom-Left, Bottom-Right
	var corners = [
		[Vector2(center.x - r, center.y - r), Vector2(1, 0), Vector2(0, 1)],
		[Vector2(center.x + r, center.y - r), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(center.x - r, center.y + r), Vector2(1, 0), Vector2(0, -1)],
		[Vector2(center.x + r, center.y + r), Vector2(-1, 0), Vector2(0, -1)]
	]

	for c in corners:
		var p: Vector2 = c[0]
		var dx: Vector2 = c[1] * arm
		var dy: Vector2 = c[2] * arm
		# Shadow
		control.draw_line(p - Vector2(0.5, 0.5), p + dx - Vector2(0.5, 0.5), dark, w + 1.0)
		control.draw_line(p - Vector2(0.5, 0.5), p + dy - Vector2(0.5, 0.5), dark, w + 1.0)
		# Line
		control.draw_line(p, p + dx, color, w)
		control.draw_line(p, p + dy, color, w)

func _draw_out_of_range_ring(control: Control, center: Vector2, r: float, color: Color) -> void:
	# Dashed circle showing potential item out of reach
	var segments = 12
	var step = TAU / segments
	var dash_len = step * 0.55
	for i in range(segments):
		var start_angle = i * step
		control.draw_arc(center, r, start_angle, start_angle + dash_len, 4, color, 1.5)

func _draw_holding_reticle(control: Control, center: Vector2, r: float, color: Color) -> void:
	# Outer subtle holding ring
	control.draw_arc(center, r, 0, TAU, 32, color, 1.5)

	# 4 directional chevrons showing 3D positioning
	var offset = r + 4.0
	var tri_size = 3.0
	# Top arrow
	control.draw_line(Vector2(center.x - tri_size, center.y - offset), Vector2(center.x, center.y - offset - tri_size), color, 1.5)
	control.draw_line(Vector2(center.x + tri_size, center.y - offset), Vector2(center.x, center.y - offset - tri_size), color, 1.5)
	# Bottom arrow
	control.draw_line(Vector2(center.x - tri_size, center.y + offset), Vector2(center.x, center.y + offset + tri_size), color, 1.5)
	control.draw_line(Vector2(center.x + tri_size, center.y + offset), Vector2(center.x, center.y + offset + tri_size), color, 1.5)
	# Left arrow
	control.draw_line(Vector2(center.x - offset, center.y - tri_size), Vector2(center.x - offset - tri_size, center.y), color, 1.5)
	control.draw_line(Vector2(center.x - offset, center.y + tri_size), Vector2(center.x - offset - tri_size, center.y), color, 1.5)
	# Right arrow
	control.draw_line(Vector2(center.x + offset, center.y - tri_size), Vector2(center.x + offset + tri_size, center.y), color, 1.5)
	control.draw_line(Vector2(center.x + offset, center.y + tri_size), Vector2(center.x + offset + tri_size, center.y), color, 1.5)

	# If aimed at pour target cup: draw animated downward pour flow
	if is_instance_valid(target_cup):
		var pour_y = center.y + r + 12.0 + fmod(pulse_clock * 8.0, 10.0)
		control.draw_circle(Vector2(center.x, pour_y), 2.5, Color(0.25, 0.95, 0.6, 0.9))

func _draw_zoom_slider(control: Control, center: Vector2) -> void:
	var alpha = clamp(zoom_display_timer, 0.0, 1.0)
	var x = center.x + 38.0
	var bar_height = 40.0
	var y_top = center.y - bar_height / 2.0
	var y_bottom = center.y + bar_height / 2.0

	# Background track
	control.draw_line(Vector2(x, y_top), Vector2(x, y_bottom), Color(0.2, 0.2, 0.2, alpha * 0.6), 3.0)
	control.draw_line(Vector2(x, y_top), Vector2(x, y_bottom), Color(0.5, 0.7, 0.9, alpha * 0.4), 1.0)

	# Current position pip
	var t = clamp((zoom_distance - zoom_min) / max(zoom_max - zoom_min, 0.01), 0.0, 1.0)
	var pip_y = lerp(y_bottom, y_top, t)
	control.draw_circle(Vector2(x, pip_y), 4.0, Color(0.35, 0.85, 1.0, alpha * 0.95))
