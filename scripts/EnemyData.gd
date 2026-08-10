class_name EnemyData
extends Resource

@export_category("Identity")
@export var enemy_name: String = "Enemy"

@export_category("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 40.0
@export var wall_damage: float = 10.0
@export var attack_cooldown: float = 1.0

@export_category("Visuals")
@export var sprite_frames: SpriteFrames
@export var scale: Vector2 = Vector2.ONE
