extends Control

@onready var hud: Node = $"../.."

func _draw() -> void:
	if hud and is_instance_valid(hud) and hud.has_method("draw_reticle"):
		hud.draw_reticle(self)

