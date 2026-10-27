class_name Item extends RigidBody3D

@onready var player:Player = $"../../Player"

var is_being_used = false
var is_held = false

# EVENTS

signal used
signal interrupted

# HELPERS

func can_be_used() -> bool:
	return not is_being_used

func can_be_interrupted() -> bool:
	return is_being_used

func get_display_name() -> String:
	return name.capitalize()

func get_status_text() -> String:
	return ""

func is_pourable() -> bool:
	return false

func get_all_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.name != "DebugMesh":
			meshes.append(child)
	return meshes

# ACTIONS

func use():
	if not can_be_used():
		return
	
	used.emit()
	
	is_being_used = true

func interupt():
	if not can_be_interrupted():
		return
	
	interrupted.emit()
	
	is_being_used = false

func kill():
	queue_free()
