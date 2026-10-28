class_name CustomerManager extends Node3D

@export var customer_scene: PackedScene = preload("res://scenes/customer.tscn")
@export var spawn_position: Vector3 = Vector3(7.5, 0.0, 3.0)
@export var exit_position: Vector3 = Vector3(7.5, 0.0, -1.5)

# Array of slot info dictionaries: { "marker": Node3D, "customer": Customer, "timer": float }
var counter_slots: Array[Dictionary] = []

func _ready() -> void:
	_init_slots()
	# Spawn initial customers after short start delay
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(_spawn_initial_customers)

func _init_slots() -> void:
	# Find any child Marker3D or Spot nodes
	for child in get_children():
		if child is Marker3D or child.name.begins_with("Spot"):
			counter_slots.append({
				"node": child,
				"customer": null,
				"respawn_timer": 0.0
			})

	# If no spot markers exist in scene tree, create 2 default counter spots
	if counter_slots.size() == 0:
		var default_spots = [
			Vector3(4.85, 0.0, 0.3),
			Vector3(4.85, 0.0, 1.7)
		]
		for i in range(default_spots.size()):
			var marker = Marker3D.new()
			marker.name = "Spot%d" % (i + 1)
			add_child(marker)
			marker.global_position = default_spots[i]
			counter_slots.append({
				"node": marker,
				"customer": null,
				"respawn_timer": 0.0
			})

func _spawn_initial_customers() -> void:
	# Spawn customer at the first spot immediately
	if counter_slots.size() > 0:
		_spawn_customer_for_slot(0)

	# Stagger the second customer by 4 seconds
	if counter_slots.size() > 1:
		var timer = get_tree().create_timer(4.0)
		timer.timeout.connect(func(): _spawn_customer_for_slot(1))

func _process(delta: float) -> void:
	for i in range(counter_slots.size()):
		var slot_info = counter_slots[i]
		if slot_info["customer"] == null and slot_info["respawn_timer"] > 0.0:
			slot_info["respawn_timer"] -= delta
			if slot_info["respawn_timer"] <= 0.0:
				_spawn_customer_for_slot(i)

func _spawn_customer_for_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= counter_slots.size():
		return
	var slot_info = counter_slots[slot_idx]
	if slot_info["customer"] != null:
		return # Already occupied

	var customer: Customer = customer_scene.instantiate()
	add_child(customer)
	slot_info["customer"] = customer

	var slot_marker: Node3D = slot_info["node"]
	var target_pos = slot_marker.global_position

	customer.setup_journey(spawn_position, target_pos, exit_position, slot_marker)
	customer.order_served.connect(_on_order_served)
	customer.order_failed.connect(_on_order_failed)
	customer.customer_departed.connect(func(c, was_satisfied): _on_customer_departed(slot_idx, was_satisfied))

func _on_order_served(_customer: Customer, earnings: float, _similarity: float) -> void:
	Global.add_cash(earnings)
	Global.record_order_served()

func _on_order_failed(_customer: Customer, _reason: String) -> void:
	pass

func _on_customer_departed(slot_idx: int, _was_satisfied: bool) -> void:
	if slot_idx >= 0 and slot_idx < counter_slots.size():
		counter_slots[slot_idx]["customer"] = null
		# Random respawn delay between 2.5 and 5.0 seconds
		counter_slots[slot_idx]["respawn_timer"] = randf_range(2.5, 5.0)

