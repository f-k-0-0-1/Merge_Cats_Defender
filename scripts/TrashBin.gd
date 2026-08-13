class_name TrashBin
extends TextureButton

@export_category("Visual")
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)

@export_category("Detection")
@export var drop_margin: float = 20.0

var original_scale: Vector2
var _bin_is_hovered: bool = false   # Renamed to avoid shadowing base class property

func _ready() -> void:
	add_to_group("trash_bin")
	original_scale = scale

	# CRITICAL FIX: Set to IGNORE so it never intercepts or blocks 
	# mouse release events from reaching the TrapManager during a drag.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# ============================================================
# POINTER DETECTION
# ============================================================

func is_pointer_inside(_world_position: Vector2) -> bool:
	# Use prefixed parameter to clear unused warning
	var rect: Rect2 = get_global_rect()
	rect = rect.grow(drop_margin)

	var viewport_mouse: Vector2 = get_viewport().get_mouse_position()
	return rect.has_point(viewport_mouse)

# ============================================================
# HOVER EFFECT
# ============================================================

func set_hovered(value: bool) -> void:
	if _bin_is_hovered == value:
		return

	_bin_is_hovered = value
	var target_scale: Vector2 = hover_scale if _bin_is_hovered else original_scale

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.12)

# ============================================================
# DELETE TRAP
# ============================================================

func delete_trap(trap: Trap) -> void:
	if trap == null:
		return

	if not is_instance_valid(trap):
		return

	var trap_name: String = "Unknown"
	if trap.trap_data != null:
		trap_name = trap.trap_data.trap_name

	print("Trash Bin: Successfully deleted trap -> ", trap_name)
	
	if trap.has_method("_find_parent_slot"):
		var slot = trap._find_parent_slot()
		if slot != null and slot.has_method("clear_trap"):
			slot.clear_trap()

	trap.queue_free()
