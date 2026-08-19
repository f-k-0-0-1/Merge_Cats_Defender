class_name CatData
extends Resource

@export_category("Theme")
@export_enum("Theme 1", "Theme 2", "Theme 3")
var theme_id: int = 0

@export_category("Identity")

@export var level: int = 1
@export var cat_name: String = "Cat"


@export_category("Combat")

@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 300.0
@export var projectile_speed: float = 500.0


@export_category("Projectile")

@export var projectile_scene: PackedScene


@export_category("Visuals")

@export var sprite_frames: SpriteFrames
