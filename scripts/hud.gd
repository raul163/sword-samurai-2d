extends CanvasLayer

const SLOT_SIZE := Vector2(10, 10)

@onready var hotbar: HBoxContainer = $VBoxContainer/Hotbar
@onready var backpack: GridContainer = $VBoxContainer/Backpack
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	health_bar.show_percentage = false
	health_bar.anchor_left = 1.0
	health_bar.anchor_right = 1.0
	health_bar.anchor_top = 0.0
	health_bar.anchor_bottom = 0.0
	health_bar.custom_minimum_size = Vector2(80, 4)
	health_bar.offset_left = -90
	health_bar.offset_right = -10
	health_bar.offset_top = 10
	health_bar.offset_bottom = 14

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.25, 0.0, 0.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color.RED
	health_bar.add_theme_stylebox_override("background", bg)
	health_bar.add_theme_stylebox_override("fill", fill)
	for i in Inventory.HOTBAR_SLOTS:
		hotbar.add_child(_make_slot())
	for i in Inventory.TOTAL_SLOTS - Inventory.HOTBAR_SLOTS:
		backpack.add_child(_make_slot())
	backpack.visible = false
	Inventory.changed.connect(_refresh)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		backpack.visible = not backpack.visible

func _make_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.set_border_width_all (1)
	style.border_color = Color.WHITE
	slot.add_theme_stylebox_override("panel", style)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon)
	return slot

func _refresh() -> void:
	var slots := hotbar.get_children() + backpack.get_children()
	for i in slots.size():
		var item = Inventory.items[i]
		slots[i].get_node("Icon").texture = item["icon"] if item else null
