extends Control

@export var tab_normal: Texture2D
@export var tab_selected: Texture2D
@export var Level_Icon_normal: Texture2D
@export var Level_Icon_Current: Texture2D

@onready var title_label: Label = $RightPanel/Title_Ribbon/TitleLabel
@onready var progress_bar: ProgressBar = $ProgressBar

@onready var home_page: Control = $RightPanel/Panel/Content/HomePage
@onready var cats_page: Control = $RightPanel/Panel/Content/CatsPage
@onready var addons_page: Control = $RightPanel/Panel/Content/AddonsPage
@onready var settings_page: Control = $RightPanel/Panel/Content/SettingsPage

@onready var tabs: Array[TextureButton] = [
	$RightPanel/Tabs/VBoxContainer/HomeTab,
	$RightPanel/Tabs/VBoxContainer/CatsTab,
	$RightPanel/Tabs/VBoxContainer/AddonTab,
	$RightPanel/Tabs/VBoxContainer/SettingsTab
]

@onready var level_button_1: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton1
@onready var level_button_2: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton2
@onready var level_button_3: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton3
@onready var level_button_4: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton4
@onready var level_button_5: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton5
@onready var level_button_6: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton6

@onready var level_icon_texture: Array[TextureButton] = [
	$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton1,
	$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton2,
	$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton3,
	$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton4,
	$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton5,
	$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton6
]

const LEVEL_1_DATA: LevelData = preload(
	"res://data/levels/level_1_data.tres"
)

const LEVEL_2_DATA: LevelData = preload(
	"res://data/levels/level_2_data.tres"
)

const LEVEL_3_DATA: LevelData = preload(
	"res://data/levels/level_3_data.tres"
)

var current_tab: int = 0
var current_level: int = 1


func _ready() -> void:
	progress_bar.visible = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0

	select_tab(0)
	select_level(1)

	cats_page.visible = false
	addons_page.visible = false
	settings_page.visible = false


func select_tab(index: int) -> void:
	current_tab = index

	for i: int in range(tabs.size()):
		if i == index:
			tabs[i].texture_normal = tab_selected
		else:
			tabs[i].texture_normal = tab_normal


func select_level(level: int) -> void:
	current_level = level

	for i: int in range(level_icon_texture.size()):
		if i == level - 1:
			level_icon_texture[i].texture_normal = Level_Icon_Current
		else:
			level_icon_texture[i].texture_normal = Level_Icon_normal


func _on_tab_1_pressed() -> void:
	select_tab(0)
	title_label.text = "LEVEL SELECT"

	home_page.visible = true
	cats_page.visible = false
	addons_page.visible = false
	settings_page.visible = false


func _on_tab_2_pressed() -> void:
	select_tab(1)
	title_label.text = "UPGRADES"

	home_page.visible = false
	cats_page.visible = true
	addons_page.visible = false
	settings_page.visible = false


func _on_tab_3_pressed() -> void:
	select_tab(2)
	title_label.text = "EXTRAS"

	home_page.visible = false
	cats_page.visible = false
	addons_page.visible = true
	settings_page.visible = false


func _on_tab_4_pressed() -> void:
	select_tab(3)
	title_label.text = "SETTINGS"

	home_page.visible = false
	cats_page.visible = false
	addons_page.visible = false
	settings_page.visible = true


func _on_back_button_pressed() -> void:
	if SceneManager._is_loading:
		return

	SceneManager.go_to_menu()


func _on_level_button_1_pressed() -> void:
	if SceneManager._is_loading:
		return

	select_level(1)

	GameplayManager.selected_level = LEVEL_1_DATA

	_start_loading()
	SceneManager.go_to_gameplay()


func _on_level_button_2_pressed() -> void:
	if SceneManager._is_loading:
		return

	select_level(2)

	GameplayManager.selected_level = LEVEL_2_DATA

	_start_loading()
	SceneManager.go_to_gameplay()


func _on_level_button_3_pressed() -> void:
	if SceneManager._is_loading:
		return

	select_level(3)

	GameplayManager.selected_level = LEVEL_3_DATA

	_start_loading()
	SceneManager.go_to_gameplay()


func _on_level_button_4_pressed() -> void:
	select_level(4)


func _on_level_button_5_pressed() -> void:
	select_level(5)


func _on_level_button_6_pressed() -> void:
	select_level(6)


func _start_loading() -> void:
	progress_bar.visible = true
	progress_bar.value = 0.0

	level_button_1.disabled = true
	level_button_2.disabled = true
	level_button_3.disabled = true
	level_button_4.disabled = true
	level_button_5.disabled = true
	level_button_6.disabled = true


func update_loading(value: float) -> void:
	progress_bar.visible = true
	progress_bar.value = clampf(value, 0.0, 100.0)
