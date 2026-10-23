
extends CharacterBody2D

@export var speed: float = 150.0
@export var jump_velocity: float = -200.0
@export var health: int = 3

@export var default_attack: Dictionary = {
	"name": "Soco",
	"damage": 1,
	"cooldown": 0.4
}

@export var sword_attack: Dictionary = {
	"name": "Espada",
	"damage": 3,
	"cooldown": 0.3
}

var current_attack: Dictionary = {}
var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false
var facing: int = 1
var attack_area_base_x: float = 0.0

var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var pickup_area: Area2D = $PickupArea


func _ready() -> void:
	current_attack = default_attack.duplicate()
	attack_area_base_x = abs(attack_area.position.x)

	if not pickup_area.area_entered.is_connected(
		_on_pickup_area_entered
	):
		pickup_area.area_entered.connect(
			_on_pickup_area_entered
		)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Movimento horizontal
	var direction: float = Input.get_axis(
		"ui_left",
		"ui_right"
	)

	velocity.x = direction * speed

	# Direção do personagem
	if direction != 0:
		facing = int(sign(direction))
		sprite.flip_h = facing < 0

		attack_area.position.x = attack_area_base_x * facing

	# Movimento com colisões
	move_and_slide()

	# Animações de movimento
	if not is_attacking:
		update_animation(direction)

	# Ataque
	if InputMap.has_action("attack"):
		if Input.is_action_just_pressed("attack") and can_attack:
			attack()


func update_animation(direction: float) -> void:
	if not is_on_floor():
		play_animation("pulo")
	elif direction != 0:
		play_animation("run")
	else:
		play_animation("parado")


func play_animation(animation_name: String) -> void:
	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(animation_name):
		return

	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func attack() -> void:
	if is_dead or is_attacking or not can_attack:
		return

	can_attack = false
	is_attacking = true

	# Guarda os dados do ataque atual
	var damage: int = int(current_attack.get("damage", 1))
	var cooldown: float = float(current_attack.get("cooldown", 0.4))

	# Animação de ataque
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	else:
		is_attacking = false
		can_attack = true
		push_warning("Crie a animação 'attack' no AnimatedSprite2D.")
		return

	# Detecta corpos atingidos
	var hit_targets: Array[Node] = []

	for body in attack_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage"):
			if not hit_targets.has(body):
				hit_targets.append(body)
				body.take_damage(damage)

	# Detecta áreas de dano dos inimigos
	for area in attack_area.get_overlapping_areas():
		var target: Node = area

		if area.has_method("take_damage"):
			target = area
		elif area.get_parent() != null and area.get_parent().has_method("take_damage"):
			target = area.get_parent()
		else:
			continue

		if target != self and not hit_targets.has(target):
			hit_targets.append(target)
			target.take_damage(damage)

	# Aguarda o fim da animação
	await sprite.animation_finished

	if is_dead:
		return

	is_attacking = false

	# Tempo de recarga
	await get_tree().create_timer(cooldown).timeout

	if is_dead:
		return

	can_attack = true


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	health = max(0, health - amount)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	can_attack = false
	velocity = Vector2.ZERO

	play_animation("morte")


func _on_pickup_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.is_in_group("sword"):
		current_attack = sword_attack.duplicate()
		area.queue_free()

		print("Espada equipada!")
		print("Dano: ", current_attack["damage"])
