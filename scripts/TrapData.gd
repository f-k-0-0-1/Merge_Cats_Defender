class_name TrapData
extends Resource

@export_category("Basic")
@export var trap_name: String = "Trap"
@export var icon: Texture2D
@export var scale: Vector2 = Vector2(0.5, 0.5)

@export_category("Health")
@export var max_health: float = 250.0

@export_category("Combat")
@export var damage: float = 20.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 2.0

@export_category("Scene")
@export var trap_scene: PackedScene
