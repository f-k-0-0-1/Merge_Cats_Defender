extends Node2D


var level: int = 1
var texture: Texture2D


@export var cat_scale: Vector2 = Vector2(1.0, 1.0)


func init(
	level_value: int,
	tex: Texture2D
) -> void:

	level = level_value
	texture = tex

	$Sprite.texture = tex
	$Sprite.scale = cat_scale
