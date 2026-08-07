extends ScrollContainer

var dragging := false

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed

	elif event is InputEventMouseMotion and dragging:
		scroll_horizontal -= int(event.relative.x)
