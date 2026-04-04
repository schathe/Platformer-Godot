extends StaticBody2D

@export var disappearing_timer : float
@export var respawn_timer = 2.0
@export var collision_shape : CollisionShape2D
@export var collision_area : CollisionShape2D

@export var shape : ColorRect
@export var disappearing_animation : AnimationPlayer

var touched = false

var colors = preload("res://assets/colors.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Connected to body_entered signal
func _on_body_entered(body: Node2D) -> void:
	_animations()
	trigger_destruction()

# Annimations of the platform
func _animations() -> void:
	if disappearing_animation.has_animation("disappearing"):
		disappearing_animation.play("disappearing")

# Make the platform disappear and trigger respawn
func trigger_destruction():
	touched = true

	# Pause the function to make the platform disappear after "disappearing_timer"
	await get_tree().create_timer(disappearing_timer).timeout
	collision_shape.disabled = true
	collision_area.disabled = true
	shape.hide()
	touched = false

	respawn()

# Make the platform respawn after "respawn_timer"
func respawn():
	# Pause the function to make the platform disappear after "disappearing_timer"
	await get_tree().create_timer(respawn_timer).timeout
	shape.modulate = colors.normal
	collision_shape.disabled = false
	collision_area.disabled = false
	shape.show()
