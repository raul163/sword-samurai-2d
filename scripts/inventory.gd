# AUTOLOAD (nome: Inventory) -> Projeto > Configurações > Autoload
extends Node

signal changed

const HOTBAR_SLOTS := 7
const TOTAL_SLOTS := 28 # 7 da barra + 3 fileiras x 7

var items: Array = []

func _ready() -> void:
	items.resize(TOTAL_SLOTS)
	items.fill(null)

func add_item(item: Dictionary) -> bool:
	for i in TOTAL_SLOTS:
		if items[i] == null:
			items[i] = item
			changed.emit()
			return true
	return false # inventário cheio
