class_name TrapItem
extends TextureButton

@export var trap_data: TrapData

var trap_manager: TrapManager = null

func _ready() -> void:
	trap_manager = get_tree().current_scene.get_node_or_null(
		"TrapManager"
	) as TrapManager

	if trap_data == null:
		push_error(
			name + ": TrapData is not assigned."
		)

	if trap_manager == null:
		push_error(
			name + ": TrapManager not found."
		)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()

func _start_drag() -> void:
	if trap_data == null:
		return

	if trap_manager == null:
		trap_manager = get_tree().current_scene.get_node_or_null(
			"TrapManager"
		) as TrapManager

	if trap_manager == null:
		return

	trap_manager.start_drag(trap_data)
