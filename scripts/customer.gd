class_name Customer extends CharacterBody3D

enum State {
	IDLE,
	WALK_IN,
	ORDERING,
	SATISFIED,
	ANGRY,
	WALK_OUT
}

var current_state: State = State.IDLE

@export var max_patience: float = 45.0
var current_patience: float = 45.0
var request: String = ""

var assigned_slot: Node3D = null
var spawn_point: Vector3
var counter_point: Vector3
var exit_point: Vector3

# References
@onready var speech_bubble: Node3D = $SpeechBubble
@onready var head_mesh: MeshInstance3D = $Mesh
@onready var eye_left: MeshInstance3D = $Mesh/EyeLeft
@onready var eye_right: MeshInstance3D = $Mesh/EyeRight
@onready var accessory_root: Node3D = $Mesh/AccessoryRoot
@onready var pickup_area: Area3D = $OrderPickup

# Customer Names & Archetypes
var customer_name: String = "Customer"
var archetype_name: String = "Patron"

# SIGNALS
signal order_served(customer: Customer, earnings: float, similarity: float)
signal order_failed(customer: Customer, reason: String)
signal customer_departed(customer: Customer, was_satisfied: bool)
signal patience_boosted(customer: Customer, new_patience: float)

func _ready() -> void:
	current_patience = max_patience
	_setup_random_appearance()

func setup_journey(from_pos: Vector3, to_counter: Vector3, to_exit: Vector3, slot: Node3D = null) -> void:
	spawn_point = from_pos
	counter_point = to_counter
	exit_point = to_exit
	assigned_slot = slot
	global_position = spawn_point
	start_walk_in()

func _setup_random_appearance() -> void:
	# Randomize skin/head material
	var palettes = [
		Color(1.0, 0.76, 0.62), # Warm Peach
		Color(0.85, 0.65, 0.48), # Coffee Tan
		Color(0.55, 0.38, 0.28), # Deep Mocha
		Color(1.0, 0.88, 0.75), # Fair Cream
		Color(0.68, 0.85, 0.78), # Fun Mint
		Color(1.0, 0.82, 0.42), # Sunny Yellow
	]
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = palettes.pick_random()
	head_mesh.material_override = head_mat

	# Random customer identity
	var names = ["Alex", "Sam", "Jordan", "Taylor", "Morgan", "Riley", "Casey", "Robin", "Charlie", "Quinn"]
	var archetypes = ["Rushed Commuter", "College Student", "Hipster Barista", "Coffee Critic", "Tourist"]
	customer_name = names.pick_random()
	archetype_name = archetypes.pick_random()

	# Adjust patience based on archetype
	if archetype_name == "Rushed Commuter":
		max_patience = 32.0
	elif archetype_name == "Coffee Critic":
		max_patience = 38.0
	else:
		max_patience = 48.0
	current_patience = max_patience

func _process(delta: float) -> void:
	if current_state == State.ORDERING:
		_process_patience(delta)
		_look_at_player(delta)

func _look_at_player(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("../../Player")
	if not player:
		player = get_node_or_null("../Player")

	if player:
		var target_pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		if global_position.distance_to(target_pos) > 0.1:
			var target_rot_y = (target_pos - global_position).normalized()
			var current_rot = -transform.basis.z
			var next_rot = current_rot.slerp(target_rot_y, delta * 4.0)
			if next_rot.length() > 0.01:
				look_at(global_position + next_rot, Vector3.UP)

func _process_patience(delta: float) -> void:
	current_patience -= delta
	if speech_bubble:
		speech_bubble.update_patience(current_patience, max_patience)

	if current_patience <= 0.0:
		_on_patience_expired()

# STATE TRANSITIONS & TWEENS

func start_walk_in() -> void:
	current_state = State.WALK_IN
	look_at(counter_point, Vector3.UP)

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var travel_time = clamp(global_position.distance_to(counter_point) / 2.2, 1.2, 3.5)
	tween.tween_property(self, "global_position", counter_point, travel_time)
	tween.tween_callback(_on_arrived_at_counter)

func _on_arrived_at_counter() -> void:
	current_state = State.ORDERING
	generate_request()

func generate_request() -> void:
	# Pick random drink from Global.DRINKS
	var drinks_dict = Global.DRINKS
	var available_keys = drinks_dict.keys()
	request = available_keys.pick_random()

	var drink_info = drinks_dict[request]
	var drink_name = drink_info['name']
	var recipes = drink_info['ingredients']

	if speech_bubble:
		speech_bubble.show_order(drink_name, request, recipes, max_patience)

func _on_patience_expired() -> void:
	current_state = State.ANGRY
	if speech_bubble:
		speech_bubble.show_reaction("Too slow! I'm leaving!", false)

	order_failed.emit(self, "Patience ran out")

	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): start_walk_out(false))

func start_walk_out(was_satisfied: bool) -> void:
	current_state = State.WALK_OUT
	if speech_bubble:
		speech_bubble.hide_bubble()

	# Rotate toward exit
	look_at(exit_point, Vector3.UP)

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var travel_time = clamp(global_position.distance_to(exit_point) / 2.5, 1.2, 3.5)
	tween.tween_property(self, "global_position", exit_point, travel_time)
	tween.tween_callback(func():
		customer_departed.emit(self, was_satisfied)
		queue_free()
	)

# DELIVERY & INTERACTION LOGIC

func give(item: Node3D) -> void:
	if current_state != State.ORDERING:
		return

	# Case 1: Patience Booster (Donut / Pastry)
	if _is_snack_item(item):
		_consume_booster(item)
		return

	# Case 2: Cup / Drink delivery
	if item is Cup:
		_evaluate_cup(item)

func _is_snack_item(item: Node3D) -> bool:
	if not item:
		return false
	if item.has_method("is_snack") and item.is_snack():
		return true
	var item_name = item.name.to_lower()
	if item_name.contains("donut") or item_name.contains("pastry") or item_name.contains("snack"):
		return true
	if item.has_meta("is_snack") and item.get_meta("is_snack") == true:
		return true
	return false

func _consume_booster(item: Node3D) -> void:
	# Add +40% patience
	var boost_amount = max_patience * 0.4
	current_patience = min(current_patience + boost_amount, max_patience)
	patience_boosted.emit(self, current_patience)

	if speech_bubble:
		speech_bubble.show_booster_reaction("Mmm, treat! (+Patience)")

	# Destroy snack
	item.queue_free()

func _evaluate_cup(cup: Cup) -> void:
	if cup.volume <= 0:
		if speech_bubble:
			speech_bubble.show_reaction("It's empty! Where's my drink?", false)
		return

	var similarity = cup.get_similarity(request)

	if similarity < 80.0:
		# Unsatisfied: penalty
		current_patience -= 12.0
		if speech_bubble:
			speech_bubble.show_reaction("That's not right! (%d%% match)" % similarity, false)
		order_failed.emit(self, "Bad recipe")
		return

	# Satisfied! Calculate Earnings & Tips
	current_state = State.SATISFIED
	var base_price = 5.0
	var accuracy_tip = ((similarity - 80.0) / 20.0) * 2.0 # $0 to $2.00
	var speed_ratio = clamp(current_patience / max_patience, 0.0, 1.0)
	var speed_tip = speed_ratio * 2.50 # $0 to $2.50
	var total_earnings = base_price + accuracy_tip + speed_tip

	var amount_str = "+$%.2f  (%.0f%% Match)" % [total_earnings, similarity]
	if speech_bubble:
		speech_bubble.show_reaction("Delicious! Thanks!", true, amount_str)

	# Clean up cup
	cup.queue_free()

	order_served.emit(self, total_earnings, similarity)

	# Depart after brief celebration
	var timer = get_tree().create_timer(2.2)
	timer.timeout.connect(func(): start_walk_out(true))

# TRIGGER CALLBACK

func _on_order_pickup_body_entered(body: Node3D) -> void:
	give(body)
