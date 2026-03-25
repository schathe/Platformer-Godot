extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var animation_player : AnimationPlayer
@export var particles : GPUParticles2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_animations()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _animations() -> void:
	if animation_player.has_animation("jump"):
		animation_player.play("jump")
	else:
		print_debug("No jump animation found")
	
	if particles:
		particles.restart()
	else:
		print_debug("No particles found")
