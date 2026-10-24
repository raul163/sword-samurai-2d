extends Control

const BG = preload("res://assets/menu_bg.png")
const PIXEL_FONT = preload("res://assets/menu_font.ttf")
const SFX_HOVER = preload("res://assets/sfx_hover.mp3")
const SFX_CONFIRM = preload("res://assets/sfx_confirm.mp3")
const SFX_PANEL = preload("res://assets/sfx_panel.mp3")
const SFX_AMBIENCE = preload("res://assets/sfx_ambience.mp3")
const GOLD = Color("f5c477")

var status_label: Label
var credits_layer: Control
var settings_layer: Control
var exit_layer: Control
var hover_player: AudioStreamPlayer
var confirm_player: AudioStreamPlayer
var panel_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var petals: Array[Dictionary] = []
var sfx_volume := 0.72
var ambience_volume := 0.32
var title_label: Label
var settings_store := ConfigFile.new()
var audio_muted := false
var petals_enabled := true
var slash_time := 0.0

func _ready() -> void:
	randomize()
	_load_settings()
	_setup_audio()
	for i in range(34):
		petals.append({"x": randf_range(0, 1280), "y": randf_range(0, 720), "speed": randf_range(9, 27), "size": randi_range(2, 5), "phase": randf_range(0.0, TAU)})
	var bg := TextureRect.new()
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.025, 0.075, 0.24)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_build_menu()
	set_process(true)
	modulate.a = 0.0
	var intro := create_tween()
	intro.tween_property(self, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _setup_audio() -> void:
	hover_player = _audio_player(SFX_HOVER, -8.0)
	confirm_player = _audio_player(SFX_CONFIRM, -5.0)
	panel_player = _audio_player(SFX_PANEL, -8.0)
	ambience_player = AudioStreamPlayer.new()
	var ambience_stream := SFX_AMBIENCE as AudioStreamMP3
	ambience_stream.loop = true
	ambience_player.stream = ambience_stream
	ambience_player.volume_db = linear_to_db(ambience_volume)
	ambience_player.bus = "Master"
	add_child(ambience_player)
	ambience_player.play()
	_apply_audio_levels()

func _audio_player(stream: AudioStream, level_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = level_db + linear_to_db(sfx_volume)
	player.bus = "Master"
	add_child(player)
	return player

func _apply_audio_levels() -> void:
	var mute_db := -60.0 if audio_muted else 0.0
	for player in [hover_player, confirm_player, panel_player]:
		player.volume_db = -8.0 + linear_to_db(maxf(sfx_volume, 0.001)) + mute_db
	if ambience_player:
		ambience_player.volume_db = linear_to_db(maxf(ambience_volume, 0.001)) + mute_db

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and not player.playing:
		player.play()

func _build_menu() -> void:
	var frame := PanelContainer.new()
	frame.anchor_left = 0.055
	frame.anchor_top = 0.075
	frame.anchor_right = 0.495
	frame.anchor_bottom = 0.91
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.035, 0.035, 0.09, 0.91)
	frame_style.border_color = Color(0.86, 0.57, 0.31, 0.9)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(3)
	frame_style.shadow_color = Color(0.01, 0.005, 0.03, 0.72)
	frame_style.shadow_size = 20
	frame_style.shadow_offset = Vector2(5, 7)
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 23)
	margin.add_theme_constant_override("margin_bottom", 19)
	frame.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	var eyebrow := _label("✦   A LENDA DO CREPÚSCULO   ✦", 13, GOLD)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(eyebrow)
	title_label = _label("SWORD\nSAMURAI", 46, Color("fff0d4"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_outline_color", Color("321c2b"))
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.add_theme_color_override("font_shadow_color", Color("05040d"))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 5)
	stack.add_child(title_label)
	var subtitle := _label("HONRA  •  AÇO  •  DESTINO", 12, Color("e6b6a0"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	var divider := ColorRect.new()
	divider.color = Color(0.82, 0.48, 0.27, 0.75)
	divider.custom_minimum_size = Vector2(250, 2)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(divider)
	var gap := Control.new()
	gap.custom_minimum_size.y = 3
	stack.add_child(gap)

	var play := _button("▶   INICIAR JORNADA", true)
	stack.add_child(play)
	play.pressed.connect(_on_play)
	var options := _button("⚙   OPÇÕES", false)
	stack.add_child(options)
	options.pressed.connect(_show_settings)
	var credits := _button("✧   CRÉDITOS", false)
	stack.add_child(credits)
	credits.pressed.connect(_show_credits)
	var exit_button := _button("×   SAIR DO JOGO", false)
	stack.add_child(exit_button)
	exit_button.pressed.connect(_show_exit_confirm)

	var bottom_gap := Control.new()
	bottom_gap.custom_minimum_size.y = 1
	stack.add_child(bottom_gap)
	status_label = _label("—  PREPARE SUA ESPADA  —", 10, GOLD)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(status_label)
	var note := _label("UMA AVENTURA 2D EM PIXEL ART", 9, Color("a99aad"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(note)

	var version := _label("PIXEL RPG  /  16-BIT", 10, GOLD)
	version.anchor_left = 0.52
	version.anchor_right = 0.98
	version.anchor_top = 0.90
	version.anchor_bottom = 0.94
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)
	var footer := _label("© SWORD SAMURAI     •     VERSÃO 1.0", 10, Color("ead2b5"))
	footer.anchor_left = 0.52
	footer.anchor_right = 0.98
	footer.anchor_top = 0.94
	footer.anchor_bottom = 0.99
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(footer)
	var controls_hint := _label("↑ ↓ NAVEGAR   •   ENTER SELECIONAR   •   ESC VOLTAR", 8, Color("bcaabd"))
	controls_hint.anchor_left = 0.055
	controls_hint.anchor_right = 0.50
	controls_hint.anchor_top = 0.94
	controls_hint.anchor_bottom = 0.99
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(controls_hint)
	play.grab_focus()
	var breathe := create_tween().set_loops()
	breathe.tween_property(title_label, "modulate", Color(1.0, 0.91, 0.77), 1.8).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(title_label, "modulate", Color.WHITE, 1.8).set_trans(Tween.TRANS_SINE)

func _label(text: String, size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_override("font", PIXEL_FONT)
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.add_theme_color_override("font_shadow_color", Color("120b1c"))
	item.add_theme_constant_override("shadow_offset_x", 2)
	item.add_theme_constant_override("shadow_offset_y", 2)
	return item

func _button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(370, 49 if not primary else 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", PIXEL_FONT)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("fff0d4"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var base := StyleBoxFlat.new()
	base.bg_color = Color("742b3b", 0.97) if primary else Color("20192e", 0.96)
	base.border_color = GOLD if primary else Color("8f718c")
	base.set_border_width_all(2)
	base.set_corner_radius_all(2)
	base.content_margin_left = 16
	base.content_margin_right = 16
	base.content_margin_top = 10
	base.content_margin_bottom = 10
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = Color("a8404f") if primary else Color("382642")
	hover.border_color = Color("fff0d4")
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("522334")	
	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.mouse_entered.connect(_on_button_hover)
	button.focus_entered.connect(_on_button_hover)
	button.pressed.connect(_on_button_confirm)
	return button

func _on_button_hover() -> void:
	_play_sfx(hover_player)

func _on_button_confirm() -> void:
	_play_sfx(confirm_player)

func _process(delta: float) -> void:
	slash_time = maxf(slash_time - delta, 0.0)
	for i in range(petals.size()):
		var p := petals[i]
		p.x -= sin(Time.get_ticks_msec() / 900.0 + p.phase) * delta * 13.0
		p.y += p.speed * delta
		if p.y > 725:
			p.y = -8
			p.x = randf_range(0, 1280)
		petals[i] = p
	queue_redraw()

func _draw() -> void:
	if petals_enabled:
		for p in petals:
			var s: float = p.size
			var center := Vector2(p.x, p.y)
			var color := Color(1.0, 0.61, 0.69, 0.72 if p.x > 650 else 0.34)
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -s), center + Vector2(s * 0.7, 0), center + Vector2(0, s), center + Vector2(-s * 0.7, 0)]), color)
	for point in [Vector2(69, 60), Vector2(624, 60), Vector2(69, 644), Vector2(624, 644)]:
		draw_rect(Rect2(point, Vector2(10, 3)), GOLD)
		draw_rect(Rect2(point, Vector2(3, 10)), GOLD)
	if slash_time > 0.0:
		var alpha := clampf(slash_time / 0.38, 0.0, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(60, 390), Vector2(60, 375), Vector2(1040, 42), Vector2(1060, 49)]), Color(1.0, 0.91, 0.68, alpha * 0.88))
		draw_line(Vector2(60, 382), Vector2(1050, 46), Color(1.0, 1.0, 0.9, alpha), 3.0, false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(exit_layer):
			exit_layer.queue_free()
			exit_layer = null
			_play_sfx(panel_player)
		elif is_instance_valid(settings_layer):
			settings_layer.queue_free()
			settings_layer = null
			_play_sfx(panel_player)
		elif is_instance_valid(credits_layer):
			credits_layer.queue_free()
			credits_layer = null
			_play_sfx(panel_player)

func _make_modal(title_text: String, half_height: float = 205.0) -> Dictionary:
	var overlay := ColorRect.new()
	overlay.color = Color(0.01, 0.008, 0.025, 0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var card := PanelContainer.new()
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -245
	card.offset_top = -half_height
	card.offset_right = 245
	card.offset_bottom = half_height
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111022")
	style.border_color = GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 18
	card.add_theme_stylebox_override("panel", style)
	overlay.add_child(card)
	overlay.modulate.a = 0.0
	var entrance := create_tween()
	entrance.tween_property(overlay, "modulate:a", 1.0, 0.16)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var heading := _label(title_text, 22, GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	_play_sfx(panel_player)
	return {"overlay": overlay, "content": content}

func _show_credits() -> void:
	if is_instance_valid(credits_layer):
		return
	var modal := _make_modal("CRÉDITOS")
	credits_layer = modal.overlay
	var content: VBoxContainer = modal.content
	var text := _label("SWORD SAMURAI\n\nUma aventura sobre honra, coragem\ne o caminho da lâmina.\n\nFeito com paixão por você.", 12, Color("eee1d5"))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(text)
	var close := _button("VOLTAR", false)
	close.pressed.connect(func(): credits_layer.queue_free(); credits_layer = null)
	content.add_child(close)
	close.grab_focus()

func _show_settings() -> void:
	if is_instance_valid(settings_layer):
		return
	var modal := _make_modal("OPÇÕES", 250.0)
	settings_layer = modal.overlay
	var content: VBoxContainer = modal.content
	_add_slider(content, "VOLUME DOS EFEITOS", sfx_volume, _set_sfx_volume)
	_add_slider(content, "SOM AMBIENTE", ambience_volume, _set_ambience_volume)
	var fullscreen := _button("TELA CHEIA: %s" % ("LIGADA" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "DESLIGADA"), false)
	content.add_child(fullscreen)
	fullscreen.pressed.connect(func(): _toggle_fullscreen(fullscreen))
	var mute_button := _button("SOM: %s" % ("MUDO" if audio_muted else "LIGADO"), false)
	content.add_child(mute_button)
	mute_button.pressed.connect(func(): _toggle_mute(mute_button))
	var petals_button := _button("PÉTALAS: %s" % ("LIGADAS" if petals_enabled else "DESLIGADAS"), false)
	content.add_child(petals_button)
	petals_button.pressed.connect(func(): _toggle_petals(petals_button))
	var close := _button("SALVAR E VOLTAR", true)
	content.add_child(close)
	close.pressed.connect(func(): settings_layer.queue_free(); settings_layer = null)
	close.grab_focus()

func _add_slider(parent: VBoxContainer, title: String, initial: float, callback: Callable) -> void:
	var label := _label("%s  ·  %d%%" % [title, int(initial * 100)], 10, Color("eee1d5"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.custom_minimum_size = Vector2(360, 28)
	parent.add_child(slider)
	slider.value_changed.connect(func(value: float):
		callback.call(value)
		label.text = "%s  ·  %d%%" % [title, int(value * 100)]
	)

func _set_sfx_volume(value: float) -> void:
	sfx_volume = value
	_apply_audio_levels()
	_save_settings()

func _set_ambience_volume(value: float) -> void:
	ambience_volume = value
	_apply_audio_levels()
	_save_settings()

func _toggle_mute(button: Button) -> void:
	audio_muted = not audio_muted
	button.text = "SOM: %s" % ("MUDO" if audio_muted else "LIGADO")
	_apply_audio_levels()
	_save_settings()

func _toggle_petals(button: Button) -> void:
	petals_enabled = not petals_enabled
	button.text = "PÉTALAS: %s" % ("LIGADAS" if petals_enabled else "DESLIGADAS")
	queue_redraw()
	_save_settings()

func _toggle_fullscreen(button: Button) -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		button.text = "TELA CHEIA: DESLIGADA"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		button.text = "TELA CHEIA: LIGADA"
	_save_settings()

func _load_settings() -> void:
	settings_store.load("user://settings.cfg")
	sfx_volume = clampf(float(settings_store.get_value("audio", "sfx", 0.72)), 0.0, 1.0)
	ambience_volume = clampf(float(settings_store.get_value("audio", "ambience", 0.32)), 0.0, 1.0)
	audio_muted = bool(settings_store.get_value("audio", "muted", false))
	petals_enabled = bool(settings_store.get_value("visual", "petals", true))
	if bool(settings_store.get_value("display", "fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _save_settings() -> void:
	settings_store.set_value("audio", "sfx", sfx_volume)
	settings_store.set_value("audio", "ambience", ambience_volume)
	settings_store.set_value("audio", "muted", audio_muted)
	settings_store.set_value("visual", "petals", petals_enabled)
	settings_store.set_value("display", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	settings_store.save("user://settings.cfg")

func _on_play() -> void:
	slash_time = 0.38
	queue_redraw()
	if ResourceLoader.exists("res://game.tscn"):
		get_tree().change_scene_to_file("res://game.tscn")
	else:
		status_label.text = "ADICIONE SUA FASE:  game.tscn"

func _show_exit_confirm() -> void:
	if is_instance_valid(exit_layer):
		return
	var modal := _make_modal("SAIR DO JOGO")
	exit_layer = modal.overlay
	var content: VBoxContainer = modal.content
	var message := _label("A aventura terminará aqui.\nTem certeza que deseja sair?", 11, Color("eee1d5"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(message)
	var leave := _button("SIM, SAIR", true)
	content.add_child(leave)
	leave.pressed.connect(_quit_game)
	var stay := _button("CONTINUAR JOGANDO", false)
	content.add_child(stay)
	stay.pressed.connect(func(): exit_layer.queue_free(); exit_layer = null)
	stay.grab_focus()

func _quit_game() -> void:
	get_tree().quit()
