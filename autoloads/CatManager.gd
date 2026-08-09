extends Node


# ============================================================
# SETTINGS
# ============================================================

const MAX_CAT_LEVEL: int = 15


# ============================================================
# CAT DATA
# ============================================================

# Complete combat data for each cat level.
#
# cat_data[1]  -> Level 1 CatData
# cat_data[2]  -> Level 2 CatData
# ...
# cat_data[15] -> Level 15 CatData

var cat_data: Dictionary = {}


# ============================================================
# CAT TEXTURES
# ============================================================

# Textures used by the existing slot / merge system.
#
# These are loaded separately from CatData.
#
# textures[1]  -> Level 1 texture
# textures[2]  -> Level 2 texture
# ...
# textures[15] -> Level 15 texture

var textures: Dictionary = {}


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	_load_cat_data()
	_load_cat_textures()


# ============================================================
# LOAD ALL CAT DATA
# ============================================================

func _load_cat_data() -> void:

	cat_data.clear()


	for level: int in range(
		1,
		MAX_CAT_LEVEL + 1
	):

		var path: String = (
			"res://data/cats/cat_level_%02d.tres"
			% level
		)


		var data: CatData = (
			load(path) as CatData
		)


		if data == null:

			push_error(
				"Could not load CatData: "
				+ path
			)

			continue


		cat_data[level] = data


	print(
		"Loaded ",
		cat_data.size(),
		"/",
		MAX_CAT_LEVEL,
		" cat data resources."
	)


# ============================================================
# LOAD ALL CAT TEXTURES
# ============================================================

func _load_cat_textures() -> void:

	textures.clear()


	for level: int in range(
		1,
		MAX_CAT_LEVEL + 1
	):

		var path: String = (
			"res://assets/cats/cat_%02d.png"
			% level
		)


		var tex: Texture2D = (
			load(path) as Texture2D
		)


		if tex == null:

			push_error(
				"Could not load cat texture: "
				+ path
			)

			continue


		textures[level] = tex


	print(
		"Loaded ",
		textures.size(),
		"/",
		MAX_CAT_LEVEL,
		" cat textures."
	)


# ============================================================
# GET CAT DATA
# ============================================================

func get_cat_data(
	level: int
) -> CatData:

	if not cat_data.has(level):

		push_error(
			"CatData not found for level %d"
			% level
		)

		return null


	return cat_data[level]


# ============================================================
# GET CAT TEXTURE
# ============================================================

func get_cat_texture(
	level: int
) -> Texture2D:

	if not textures.has(level):

		push_error(
			"Cat texture not found for level %d"
			% level
		)

		return null


	return textures[level]


# ============================================================
# CHECK CAT LEVEL
# ============================================================

func has_cat_level(
	level: int
) -> bool:

	return cat_data.has(level)


# ============================================================
# CHECK UPGRADE
# ============================================================

func can_upgrade(
	level: int
) -> bool:

	return (
		level >= 1
		and level < MAX_CAT_LEVEL
		and cat_data.has(level + 1)
	)


# ============================================================
# GET NEXT CAT DATA
# ============================================================

func get_next_cat_data(
	level: int
) -> CatData:

	var next_level: int = level + 1


	if not cat_data.has(next_level):

		push_error(
			"No CatData available for level %d"
			% next_level
		)

		return null


	return cat_data[next_level]
