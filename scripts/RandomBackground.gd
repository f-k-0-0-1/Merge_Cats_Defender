extends Sprite2D

@export_category("Backgrounds")
@export var backgrounds: Array[Texture2D] = []


func _ready() -> void:
	if backgrounds.is_empty():
		push_warning("RandomBackground: No backgrounds assigned.")
		return

	texture = backgrounds.pick_random()
