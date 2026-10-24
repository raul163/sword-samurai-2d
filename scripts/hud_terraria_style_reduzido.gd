extends CanvasLayer

## HUD com hotbar e inventário em um estilo pixel-art inspirado no Terraria.
## Requer um Autoload chamado Inventory com:
## - HOTBAR_SLOTS
## - TOTAL_SLOTS
## - items
## - changed (signal)

const SLOT_SIZE := Vector2(7, 7)
const UI_MARGIN := 16.0

@onready var ui_root: VBoxContainer = $VBoxContainer
@onready var hotbar: HBoxContainer = $VBoxContainer/Hotbar
@onready var backpack: GridContainer = $VBoxContainer/Backpack
@onready var health_bar: Control = $HealthBar

var _selected_slot := 0
var _slot_controls: Array[Panel] = []
var _inventory_background: Panel
var _inventory_title: Label

func _ready() -> void:
	_setup_layout()
	_setup_inventory_background()
	_setup_inventory_title()
	_setup_slots()
	_setup_health_bar()

	backpack.visible = false
	if not Inventory.changed.is_connected(_refresh):
		Inventory.changed.connect(_refresh)

	_refresh()
	call_deferred("_sync_inventory_background")

func _setup_layout() -> void:
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui_root.position = Vector2(UI_MARGIN, UI_MARGIN)
	ui_root.add_theme_constant_override("separation", 6)

	hotbar.add_theme_constant_override("separation", 3)
	backpack.columns = 10
	backpack.add_theme_constant_override("h_separation", 3)
	backpack.add_theme_constant_override("v_separation", 3)

	ui_root.resized.connect(_sync_inventory_background)
	backpack.visibility_changed.connect(_sync_inventory_background)

func _setup_inventory_background() -> void:
	_inventory_background = Panel.new()
	_inventory_background.name = "InventoryBackground"
	_inventory_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory_background.z_index = -1

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.055, 0.94)
	style.border_color = Color("#68727b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 5
	_inventory_background.add_theme_stylebox_override("panel", style)

	add_child(_inventory_background)
	move_child(_inventory_background, 0)

func _setup_inventory_title() -> void:
	_inventory_title = Label.new()
	_inventory_title.name = "InventoryTitle"
	_inventory_title.text = "INVENTÁRIO"
	_inventory_title.visible = false
	_inventory_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory_title.add_theme_font_size_override("font_size", 6)
	_inventory_title.add_theme_color_override("font_color", Color("#f1f1e8"))
	_inventory_title.add_theme_color_override("font_shadow_color", Color("#000000"))
	_inventory_title.add_theme_constant_override("shadow_offset_x", 2)
	_inventory_title.add_theme_constant_override("shadow_offset_y", 2)

	ui_root.add_child(_inventory_title)
	# Mantém o título entre a hotbar e a grade da mochila.
	ui_root.move_child(_inventory_title, 1)

func _setup_slots() -> void:
	for child in hotbar.get_children():
		child.free()
	for child in backpack.get_children():
		child.free()

	_slot_controls.clear()

	for i in Inventory.HOTBAR_SLOTS:
		var hotbar_slot := _make_slot(i, false)
		hotbar.add_child(hotbar_slot)
		_slot_controls.append(hotbar_slot)

	for i in range(Inventory.HOTBAR_SLOTS, Inventory.TOTAL_SLOTS):
		var backpack_slot := _make_slot(i, false)
		backpack.add_child(backpack_slot)
		_slot_controls.append(backpack_slot)

func _make_slot(index: int, show_key: bool) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_slot_gui_input.bind(index))

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 5
	icon.offset_top = 5
	icon.offset_right = -5
	icon.offset_bottom = -5
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)

	var count := Label.new()
	count.name = "Count"
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.offset_left = 3
	count.offset_top = 1
	count.offset_right = -4
	count.offset_bottom = -2
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.add_theme_font_size_override("font_size", 13)
	count.add_theme_color_override("font_color", Color.WHITE)
	count.add_theme_color_override("font_shadow_color", Color.BLACK)
	count.add_theme_constant_override("shadow_offset_x", 2)
	count.add_theme_constant_override("shadow_offset_y", 2)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)

	if show_key:
		var key_label := Label.new()
		key_label.name = "Key"
		key_label.text = str((index + 1) % 10)
		key_label.position = Vector2(4, 1)
		key_label.size = Vector2(12, 13)
		key_label.add_theme_font_size_override("font_size", 10)
		key_label.add_theme_color_override("font_color", Color("#cbd0d5"))
		key_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		key_label.add_theme_constant_override("shadow_offset_x", 1)
		key_label.add_theme_constant_override("shadow_offset_y", 1)
		key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(key_label)

	_set_slot_style(slot, index == _selected_slot)
	return slot

func _set_slot_style(slot: Panel, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)

	if selected:
		style.bg_color = Color("#555346")
		style.border_color = Color("#fff3a6")
		style.shadow_color = Color(1, 0.8, 0.2, 0.35)
		style.shadow_size = 3
	else:
		style.bg_color = Color("#252b31")
		style.border_color = Color("#67727b")

	slot.add_theme_stylebox_override("panel", style)

func _setup_health_bar() -> void:
	# Barra menor no canto superior direito.
	health_bar.anchor_left = 1.0
	health_bar.anchor_right = 1.0
	health_bar.anchor_top = 0.0
	health_bar.anchor_bottom = 0.0
	health_bar.offset_left = -166
	health_bar.offset_right = -16
	health_bar.offset_top = 16
	health_bar.offset_bottom = 30
	health_bar.custom_minimum_size = Vector2(150, 14)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.z_index = 10

	# Funciona com o PixelHealthBar. O fallback permite manter temporariamente
	# uma ProgressBar antiga enquanto a cena não for atualizada.
	if health_bar.has_method("set_health"):
		health_bar.set_health(100.0, 100.0)
	elif health_bar is ProgressBar:
		var old_bar := health_bar as ProgressBar
		old_bar.show_percentage = false
		old_bar.max_value = 100.0
		old_bar.value = 100.0

		var background := StyleBoxFlat.new()
		background.bg_color = Color("#500000")
		background.set_border_width_all(3)
		background.border_color = Color("#171a1e")

		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("#e30613")
		fill.set_border_width_all(2)
		fill.border_color = Color("#ff4a4a")

		old_bar.add_theme_stylebox_override("background", background)
		old_bar.add_theme_stylebox_override("fill", fill)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_backpack()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_slot(_selected_slot - 1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_slot(_selected_slot + 1)
			get_viewport().set_input_as_handled()

	if event is InputEventScreenTouch and event.pressed:
		# O clique real do slot é tratado pelo gui_input; aqui não consumimos o toque.
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_slot := -1
		match event.keycode:
			KEY_1: key_slot = 0
			KEY_2: key_slot = 1
			KEY_3: key_slot = 2
			KEY_4: key_slot = 3
			KEY_5: key_slot = 4
			KEY_6: key_slot = 5
			KEY_7: key_slot = 6
			KEY_8: key_slot = 7
			KEY_9: key_slot = 8
			KEY_0: key_slot = 9

		if key_slot >= 0 and key_slot < Inventory.HOTBAR_SLOTS:
			_select_slot(key_slot)
			get_viewport().set_input_as_handled()

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_slot(index)
	elif event is InputEventScreenTouch and event.pressed:
		_select_slot(index)

func _select_slot(index: int) -> void:
	if _slot_controls.is_empty():
		return

	_selected_slot = posmod(index, _slot_controls.size())

	# Se o seu Inventory tiver esse método, a seleção também é enviada para ele.
	if _selected_slot < Inventory.HOTBAR_SLOTS and Inventory.has_method("select_slot"):
		Inventory.select_slot(_selected_slot)

	_apply_slot_selection()

func _apply_slot_selection() -> void:
	for i in _slot_controls.size():
		_set_slot_style(_slot_controls[i], i == _selected_slot)

func _toggle_backpack() -> void:
	backpack.visible = not backpack.visible
	_inventory_title.visible = backpack.visible
	call_deferred("_sync_inventory_background")

func _sync_inventory_background() -> void:
	if not is_instance_valid(_inventory_background):
		return

	var content_size := ui_root.size
	if content_size.x <= 0.0 or content_size.y <= 0.0:
		content_size = ui_root.get_combined_minimum_size()

	_inventory_background.position = ui_root.position - Vector2(8, 8)
	_inventory_background.size = content_size + Vector2(16, 16)

func _refresh() -> void:
	for i in _slot_controls.size():
		var slot := _slot_controls[i]
		var item = Inventory.items[i] if i < Inventory.items.size() else null
		var icon := slot.get_node("Icon") as TextureRect
		var count := slot.get_node("Count") as Label

		if item == null:
			icon.texture = null
			count.text = ""
			continue

		if item is Dictionary:
			icon.texture = item.get("icon", null)
			var amount := _get_item_amount(item)
			count.text = str(amount) if amount > 1 else ""
		else:
			icon.texture = null
			count.text = ""

	_apply_slot_selection()

func _get_item_amount(item: Dictionary) -> int:
	for key in ["amount", "quantity", "count", "stack"]:
		if item.has(key):
			return maxi(int(item[key]), 1)
	return 1

## Chame esta função quando a vida do jogador mudar.
## Exemplo: $HUD.set_health(player.health, player.max_health)
func set_health(current: float, maximum: float) -> void:
	if health_bar.has_method("set_health"):
		health_bar.set_health(current, maximum)
	elif health_bar is ProgressBar:
		var old_bar := health_bar as ProgressBar
		old_bar.max_value = maximum
		old_bar.value = current
