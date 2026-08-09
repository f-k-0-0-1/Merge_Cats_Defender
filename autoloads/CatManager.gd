extends Node


var textures: Dictionary = {}


const MAX_CAT_LEVEL := 15


func _ready() -> void:

	var folder := "res://assets/cats/"

	for level in range(1, MAX_CAT_LEVEL + 1):

		var path := folder + "cat_%02d.png" % level

		var tex: Texture2D = load(path)

		if tex:

			textures[level] = tex

		else:

			push_error(
				"Missing cat texture for level %d"
				% level
			)
