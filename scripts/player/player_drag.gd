extends RayCast3D

const MAX_INTERACT_DISTANCE = 2.0
const MAX_DETECTION_DISTANCE = 3.5

var DRAG_FORCE = 350.0
var DRAG_RELATIVE_POSITION = Vector3.UP * .1

var ZOOM_SPEED = 0.15
var ZOOM_MIN = 0.5
var ZOOM_MAX = 1.65

var STABILISATION_SPEED = 3.5
var STABILISATION_ANGLE = Vector3(.2, 1, 0)

var drag_object: RigidBody3D
var drag_distance: float
var drag_angle: Vector3

# State tracking for indicator system
var current_aimed_object: Node = null
var current_aimed_distance: float = -1.0
var is_aimed_in_range: bool = false
var target_cup: Node = null

# Materials for 3D outline highlighting
var highlight_mat_in_range: StandardMaterial3D
var highlight_mat_out_of_range: StandardMaterial3D
var highlight_mat_held: StandardMaterial3D
var highlight_mat_target: StandardMaterial3D

# SIGNALS FOR HUD & INDICATOR
signal target_changed(target_item: Node, distance: float, in_range: bool)
signal drag_started(item: Node)
signal drag_stopped(item: Node)
signal drag_distance_changed(distance: float, min_dist: float, max_dist: float)
signal pour_target_changed(cup_item: Node)

func _ready() -> void:
	target_position = Vector3(0, 0, -MAX_DETECTION_DISTANCE)
	collision_mask = 4
	_setup_highlight_materials()

func _setup_highlight_materials() -> void:
	# In-range: warm barista gold
	highlight_mat_in_range = StandardMaterial3D.new()
	highlight_mat_in_range.cull_mode = BaseMaterial3D.CULL_FRONT
	highlight_mat_in_range.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_mat_in_range.grow = true
	highlight_mat_in_range.grow_amount = 0.007
	highlight_mat_in_range.albedo_color = Color(0.96, 0.68, 0.22, 0.85)
	highlight_mat_in_range.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Out-of-range: muted gray
	highlight_mat_out_of_range = StandardMaterial3D.new()
	highlight_mat_out_of_range.cull_mode = BaseMaterial3D.CULL_FRONT
	highlight_mat_out_of_range.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_mat_out_of_range.grow = true
	highlight_mat_out_of_range.grow_amount = 0.005
	highlight_mat_out_of_range.albedo_color = Color(0.65, 0.65, 0.65, 0.45)
	highlight_mat_out_of_range.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Held: vibrant cyan glow
	highlight_mat_held = StandardMaterial3D.new()
	highlight_mat_held.cull_mode = BaseMaterial3D.CULL_FRONT
	highlight_mat_held.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_mat_held.grow = true
	highlight_mat_held.grow_amount = 0.006
	highlight_mat_held.albedo_color = Color(0.3, 0.82, 1.0, 0.75)
	highlight_mat_held.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Target cup (for pouring or adding ingredients): emerald green
	highlight_mat_target = StandardMaterial3D.new()
	highlight_mat_target.cull_mode = BaseMaterial3D.CULL_FRONT
	highlight_mat_target.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_mat_target.grow = true
	highlight_mat_target.grow_amount = 0.008
	highlight_mat_target.albedo_color = Color(0.25, 0.95, 0.55, 0.85)
	highlight_mat_target.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

# 3D HIGHLIGHTING HELPERS

func apply_highlight(node: Node, material: StandardMaterial3D) -> void:
	if not is_instance_valid(node):
		return
	for child in node.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.name != "DebugMesh":
			child.material_overlay = material
	if node is MeshInstance3D:
		node.material_overlay = material

func clear_highlight(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for child in node.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.material_overlay != null:
			child.material_overlay = null
	if node is MeshInstance3D and node.material_overlay != null:
		node.material_overlay = null

# HELPERS

func get_collision_distance() -> float:
	if not is_colliding():
		return -1.0
	return global_transform.origin.distance_to(get_collision_point())

func is_object_draggable(object) -> bool:
	if not object:
		return false
	if object is RigidBody3D:
		return true
	return false

func get_draggable_aimed() -> RigidBody3D:
	var object_aimed = get_collider()
	if is_object_draggable(object_aimed):
		return object_aimed
	return null

func get_drag_position() -> Vector3:
	var forward = -get_global_transform().basis.z
	return global_position + forward * drag_distance + DRAG_RELATIVE_POSITION

func get_drag_velocity(
	delta: float,
	force: float = DRAG_FORCE,
	object: RigidBody3D = drag_object,
) -> Vector3:
	if not object or not is_instance_valid(object):
		return Vector3.ZERO
	return (get_drag_position() - object.global_position) * delta * force

# SETTERS

func set_drag_distance(value: float) -> void:
	drag_distance = clamp(value, ZOOM_MIN, ZOOM_MAX)
	drag_distance_changed.emit(drag_distance, ZOOM_MIN, ZOOM_MAX)

func set_drag_object(object: RigidBody3D) -> void:
	if drag_object:
		stop_dragging()
	
	drag_object = object
	if not is_instance_valid(drag_object):
		return

	# Prevent raycast from hitting the object we are holding
	add_exception(drag_object)
	
	# Connect tree_exited so if the object is consumed (e.g. into a cup) it safely stops
	if not drag_object.tree_exited.is_connected(_on_drag_object_tree_exited):
		drag_object.tree_exited.connect(_on_drag_object_tree_exited)

	if drag_object is Item:
		drag_object.is_held = true

	apply_highlight(drag_object, highlight_mat_held)
	drag_started.emit(drag_object)

func set_drag_angle(angle: Vector3 = STABILISATION_ANGLE) -> void:
	drag_angle = angle

# ACTIONS

func start_dragging(
	object: RigidBody3D = get_draggable_aimed(),
	distance: float = get_collision_distance(),
) -> void:
	if not object:
		return
	
	# Only allow picking up if within reach
	if distance > MAX_INTERACT_DISTANCE or distance <= 0.0:
		return

	if drag_object:
		stop_dragging()

	set_drag_object(object)
	set_drag_distance(distance)
	set_drag_angle()

func stop_dragging() -> void:
	if not drag_object:
		return

	var obj = drag_object
	drag_object = null

	if is_instance_valid(obj):
		obj.sleeping = false
		remove_exception(obj)
		if obj.tree_exited.is_connected(_on_drag_object_tree_exited):
			obj.tree_exited.disconnect(_on_drag_object_tree_exited)
		if obj is Item:
			obj.is_held = false
		clear_highlight(obj)

	# Also clear any target cup highlight
	if is_instance_valid(target_cup):
		clear_highlight(target_cup)
		target_cup = null
		pour_target_changed.emit(null)

	drag_stopped.emit(obj)

func _on_drag_object_tree_exited() -> void:
	stop_dragging()

func apply_drag(
	delta: float,
	force: float = DRAG_FORCE,
	object: RigidBody3D = drag_object,
) -> void:
	if not object or not is_instance_valid(object):
		return

	object.linear_velocity = get_drag_velocity(delta, force, object)
	object.angular_velocity = Vector3.ZERO
	object.rotation = object.rotation.lerp(drag_angle, delta * STABILISATION_SPEED)

# DETECTION & HIGHLIGHT UPDATE LOOP

func _process(_delta: float) -> void:
	_update_raycast_targeting()

func _update_raycast_targeting() -> void:
	var aimed = get_draggable_aimed()
	var dist = get_collision_distance()
	var in_range = (dist > 0.0 and dist <= MAX_INTERACT_DISTANCE)

	if drag_object:
		# While holding an object, check if aiming at a destination cup
		var new_target_cup: Node = null
		if aimed and (aimed is Cup or aimed.name.to_lower().contains("cup")):
			new_target_cup = aimed

		if new_target_cup != target_cup:
			if is_instance_valid(target_cup):
				clear_highlight(target_cup)
			target_cup = new_target_cup
			if is_instance_valid(target_cup):
				apply_highlight(target_cup, highlight_mat_target)
			pour_target_changed.emit(target_cup)

		# Keep held item highlighted
		if is_instance_valid(drag_object):
			apply_highlight(drag_object, highlight_mat_held)
		return

	# Not dragging: update hover target highlights
	if aimed != current_aimed_object or in_range != is_aimed_in_range:
		# Clear old target highlight if changed
		if is_instance_valid(current_aimed_object) and current_aimed_object != aimed:
			clear_highlight(current_aimed_object)

		current_aimed_object = aimed
		current_aimed_distance = dist
		is_aimed_in_range = in_range

		if is_instance_valid(current_aimed_object):
			var mat = highlight_mat_in_range if in_range else highlight_mat_out_of_range
			apply_highlight(current_aimed_object, mat)

		target_changed.emit(current_aimed_object, current_aimed_distance, is_aimed_in_range)
	else:
		# Update distance if aiming at the same object
		if is_instance_valid(current_aimed_object) and abs(dist - current_aimed_distance) > 0.05:
			current_aimed_distance = dist
			target_changed.emit(current_aimed_object, current_aimed_distance, is_aimed_in_range)

# CONTROLS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('drag') or (event is InputEventScreenTouch and event.pressed):
		start_dragging()
	elif event.is_action_released('drag') or (event is InputEventScreenTouch and not event.pressed):
		stop_dragging()

	if event.is_action_pressed('zoom_in'):
		set_drag_distance(drag_distance - ZOOM_SPEED)
	elif event.is_action_pressed('zoom_out'):
		set_drag_distance(drag_distance + ZOOM_SPEED)

func _physics_process(delta: float) -> void:
	apply_drag(delta)
