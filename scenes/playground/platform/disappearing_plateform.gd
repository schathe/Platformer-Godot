extends StaticBody2D

@export var disappearing_delay : float
@export var reappearing_delay = 3.0
@export var collision_shape : StaticBody2D

@export var shape : ColorRect

var touched = false
var timer = 0.0

var initial_scale = Vector2(1, 1)
var initial_color = Color.WHITE

var colors = preload("res://assets/colors.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if shape != null:
		initial_scale = shape.scale
		initial_color = shape.color
	
	collision_shape..connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func _on_body_entered(other) -> void:
	if other.is_on_group("Player") and not touched:
		print("bite")
