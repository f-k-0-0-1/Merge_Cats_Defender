class_name LevelData
extends Resource


@export_category("Level Identity")
@export var level_id: int = 1
@export var level_name: String = "Level 1"


@export_category("Waves")
@export var waves: Array[WaveData] = []


@export_category("Starting Cats")
@export var starting_cats: int = 2
@export var starting_cat_level: int = 1
@export var buy_cat_level: int = 1


@export_category("Defense Wall")
@export var wall_max_health: int = 500
@export var wall_repair_amount: int = 100


@export_category("Tutorial")
@export var tutorial_enabled: bool = false
