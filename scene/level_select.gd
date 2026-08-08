extends Control

@export var tab_normal: Texture2D
@export var tab_selected: Texture2D

@export var Level_Icon_normal: Texture2D
@export var Level_Icon_Current: Texture2D

@onready var title_label: Label = $RightPanel/Title_Ribbon/TitleLabel

@onready var home_page: Control = $RightPanel/Panel/Content/HomePage
@onready var cats_page: Control = $RightPanel/Panel/Content/CatsPage
@onready var addons_page: Control = $RightPanel/Panel/Content/AddonsPage
@onready var shop_page: Control = $RightPanel/Panel/Content/ShopPage

@onready var tabs: Array[TextureButton] = [
$RightPanel/Tabs/VBoxContainer/HomeTab,
$RightPanel/Tabs/VBoxContainer/CatsTab,
$RightPanel/Tabs/VBoxContainer/AddonTab,
$RightPanel/Tabs/VBoxContainer/ShopTab
]

@onready var level_button_1: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton1
@onready var level_button_2: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton2
@onready var level_button_3: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton3
@onready var level_button_4: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton4
@onready var level_button_5: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton5
@onready var level_button_6: TextureButton = $RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton6

@onready var LevelIconTexure: Array[TextureButton] = [
$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton1,
$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton2,
$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton3,
$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton4,
$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton5,
$RightPanel/Panel/Content/HomePage/ScrollContainer/MapContainer/LevelButton6
]

var current_tab := 0
var current_level := 1

func _ready() -> void:
	select_tab(0)
	select_level(1)
	cats_page.visible = false
	addons_page.visible = false
	shop_page.visible = false

func select_tab(index: int) -> void:
	current_tab = index

	for i in range(tabs.size()):
		if i == index:
			tabs[i].texture_normal = tab_selected
		else:
			tabs[i].texture_normal = tab_normal

func select_level(level: int) -> void:
	current_level = level

	for i in range(LevelIconTexure.size()):
		if i == level - 1:
			LevelIconTexure[i].texture_normal = Level_Icon_Current
		else:
			LevelIconTexure[i].texture_normal = Level_Icon_normal

func _on_tab_1_pressed() -> void:
	select_tab(0)
	title_label.text = "Level Select"
	cats_page.visible = false
	addons_page.visible = false
	shop_page.visible = false
	home_page.visible = true

func _on_tab_2_pressed() -> void:
	select_tab(1)
	title_label.text = "UPGRADES"
	home_page.visible = false
	addons_page.visible = false
	shop_page.visible = false
	cats_page.visible = true

func _on_tab_3_pressed() -> void:
	select_tab(2)
	title_label.text = "EXTRAS"
	home_page.visible = false
	cats_page.visible = false
	shop_page.visible = false
	addons_page.visible = true

func _on_tab_4_pressed() -> void:
	select_tab(3)
	title_label.text = "SHOP"
	home_page.visible = false
	cats_page.visible = false
	addons_page.visible = false
	shop_page.visible = true

func _on_back_button_pressed() -> void:
	SceneManager.go_to_menu()


func _on_level_button_1_pressed() -> void:
	select_level(1)

func _on_level_button_2_pressed() -> void:
	select_level(2)

func _on_level_button_3_pressed() -> void:
	select_level(3)

func _on_level_button_4_pressed() -> void:
	select_level(4)

func _on_level_button_5_pressed() -> void:
	select_level(5)

func _on_level_button_6_pressed() -> void:
	select_level(6)
