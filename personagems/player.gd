extends CharacterBody2D

@export var speed := 150.0
@export var jump_velocity := -200.0
@export var health := 3

@export var default_attack := {"name": "Soco", "damage": 1, "cooldown": 0.4}
@export var sword_attack := {"name": "Espada", "damage": 3, "cooldown": 0.3}

var current_attack: Dictionary
var can_attack := true
var is_attacking := false
var is_dead := false
var facing := 1

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var pickup_area: Area2D = $PickupArea


func _ready() -> void:
	current_attack = default_attack
	pickup_area.area_entered.connect(_on_pickup_area_entered)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	if direction != 0:
		facing = int(sign(direction))
		sprite.flip_h = facing < 0
		attack_area.position.x = abs(attack_area.position.x) * facing

	move_and_slide()

	if not is_attacking:
		update_animation(direction)

	if Input.is_action_just_pressed("attack") and can_attack:
		attack()


func update_animation(direction: float) -> void:
	if not is_on_floor():
		sprite.play("pulo")
	elif direction != 0:
		sprite.play("run")
	else:
		sprite.play("parado")


func attack() -> void:
	can_attack = false
	is_attacking = true
	sprite.play("attack")

	for body in attack_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage"):
			body.take_damage(current_attack["damage"])

	await sprite.animation_finished
	is_attacking = false

	await get_tree().create_timer(current_attack["cooldown"]).timeout
	can_attack = true


func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("morte")


func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("sword"):
		current_attack = sword_attack
		area.queue_free()
