extends Node

var textures: Dictionary = {}
var cat_data: Dictionary = {}

const MAX_CAT_LEVEL := 15

func _ready() -> void:
	_load_cat_data()
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
func _load_cat_data() -> void:

	for level in range(1, MAX_CAT_LEVEL + 1):

		var path := "res://data/cats/cat_level_%02d.tres" % level

		var data := load(path) as CatData

		if data == null:
			push_error(
				"Could not load CatData: " + path
			)
			continue

		cat_data[level] = data


func get_cat_data(level: int) -> CatData:

	if not cat_data.has(level):

		push_error(
			"CatData not found for level %d" % level
		)

		return null

	return cat_data[level]
