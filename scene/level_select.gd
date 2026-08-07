extends Control

@export var tab_normal: Texture2D
@export var tab_selected: Texture2D

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

var current_tab := 0

func _ready() -> void:
	select_tab(0)
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
