class_name TrapData
extends Resource

@export_category("Trap Behavior")
@export_enum("NORMAL", "EXPLOSIVE") var trap_type: String = "NORMAL"

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

@export_category("Explosion")
@export var explosion_radius: float = 150.0
@export var explosion_damage: float = 50.0
@export var explosion_delay: float = 0.35
