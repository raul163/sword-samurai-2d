extends Control
class_name PixelHealthBar

## Barra horizontal pixelada, inspirada na imagem enviada.
## Mantém a mesma API básica de uma ProgressBar: value e max_value.

@export var max_value: float = 100.0:
	set(new_value):
		max_value = maxf(new_value, 1.0)
		value = clampf(value, 0.0, max_value)
		queue_redraw()

@export var value: float = 100.0:
	set(new_value):
		value = clampf(new_value, 0.0, max_value)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(320, 28)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_health(current: float, maximum: float) -> void:
	max_value = maximum
	value = current

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var ratio := 0.0
	if max_value > 0.0:
		ratio = clampf(value / max_value, 0.0, 1.0)

	# Moldura externa preta, com recortes pixelados nas pontas.
	draw_rect(Rect2(3, 0, size.x - 6, size.y), Color("#111317"))
	draw_rect(Rect2(0, 6, size.x, size.y - 12), Color("#111317"))

	# Borda metálica cinza.
	draw_rect(Rect2(4, 3, size.x - 8, size.y - 6), Color("#555d64"))
	draw_rect(Rect2(6, 5, size.x - 12, size.y - 10), Color("#171a1e"))

	# Área vazia da vida.
	var inner := Rect2(8, 8, size.x - 16, size.y - 16)
	draw_rect(inner, Color("#5b0000"))

	# Preenchimento vermelho.
	var fill_width : float =floor(inner.size.x * ratio)
	if fill_width > 0.0:
		var fill := Rect2(inner.position, Vector2(fill_width, inner.size.y))
		draw_rect(fill, Color("#e30613"))

		# Brilho superior e sombra inferior, como no estilo pixel-art.
		var shine_width := minf(fill_width, inner.size.x)
		draw_rect(Rect2(inner.position + Vector2(0, 1), Vector2(shine_width, 3)), Color("#ff4a4a"))
		draw_rect(Rect2(inner.position + Vector2(0, inner.size.y - 3), Vector2(shine_width, 3)), Color("#a90009"))

	# Tampas laterais da barra.
	draw_rect(Rect2(0, 7, 4, size.y - 14), Color("#3d454c"))
	draw_rect(Rect2(size.x - 4, 7, 4, size.y - 14), Color("#3d454c"))
