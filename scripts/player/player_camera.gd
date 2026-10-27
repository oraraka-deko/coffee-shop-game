extends Camera3D

@onready var body:CharacterBody3D = $".."
@onready var camera:Camera3D = $"."

const MOUSE_MODE = Input.MOUSE_MODE_CAPTURED

const SENSETIVITY = 0.7
const MIN_ROTATION = -75
const MAX_ROTATION = 85

const BOBBING_FREQUENCY = 4.3
const BOBBING_AMPLITUDE = 0.035

var bobbing_offset = 0.0

func _ready():
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(MOUSE_MODE)

func apply_rotation(
		event:InputEventMouseMotion,
		sensetivity:float=SENSETIVITY,
		x_min:float=MIN_ROTATION,
		x_max:float=MAX_ROTATION,
		):
	body.rotate_y(-event.relative.x * sensetivity / 1000)
	rotate_x(-event.relative.y * sensetivity / 1000)
	rotation.x = clamp(
		rotation.x,
		deg_to_rad(x_min),
		deg_to_rad(x_max)
		)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and not DisplayServer.is_touchscreen_available():
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or DisplayServer.is_touchscreen_available():
			apply_rotation(event)
	elif event is InputEventScreenDrag:
		# Touch screen drag: allow looking around on the right side (avoiding left joystick area)
		var vp_width = get_viewport().get_visible_rect().size.x
		if event.position.x > vp_width * 0.35:
			var motion = InputEventMouseMotion.new()
			motion.relative = event.relative
			apply_rotation(motion, SENSETIVITY * 1.8)

func apply_head_bobbing(
		delta:float,
		offset:float,
		freq:float=BOBBING_FREQUENCY,
		ampl:float=BOBBING_AMPLITUDE,
	) -> float:
	offset += delta * body.velocity.length() * float(body.is_on_floor())
	
	var local_camera_position = Vector3(
		cos(offset * freq / 2) * ampl,
		sin(offset * freq) * ampl,
		0
	)
	
	transform.origin = local_camera_position
	
	return offset

func _process(delta):
	bobbing_offset = apply_head_bobbing(delta, bobbing_offset)
