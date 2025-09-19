extends CharacterBody2D

@export var start_speed: float = 360.0
@export var speed_increment: float = 25.0
@export var max_speed: float = 900.0

# Drag a circular PNG here (e.g., 16×16). If auto_resize_shape = true, the radius will match half the smallest texture dimension.
@export var ball_texture: Texture2D
@export var auto_resize_shape: bool = true

signal paddle_hit
signal wall_hit

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var sprite: Sprite2D = $Sprite2D
@onready var circle_shape: CircleShape2D = $CollisionShape2D.shape as CircleShape2D

func _ready() -> void:
	rng.randomize()
	_apply_texture_if_any()

func reset_ball(randomize_direction: bool = true) -> void:
	# Center on current viewport (works even if you later change the window size)
	var vp_center: Vector2 = get_viewport_rect().size * 0.5
	global_position = vp_center

	var dir_x: float = (-1.0 if rng.randf() < 0.5 else 1.0)
	var ang: float = (deg_to_rad(rng.randf_range(-15.0, 15.0)) if randomize_direction else 0.0)
	velocity = Vector2(dir_x, 0.0).rotated(ang).normalized() * start_speed

func _physics_process(delta: float) -> void:
	var result: Variant = move_and_collide(velocity * delta)
	if result != null:
		var collision: KinematicCollision2D = result
		var collider: Node2D = collision.get_collider() as Node2D
		if collider and collider.is_in_group(&"paddle"):
			# Angle bounce based on where the ball hit the paddle
			emit_signal("paddle_hit")
			var paddle_cs: CollisionShape2D = collider.get_node("CollisionShape2D") as CollisionShape2D
			var rect: RectangleShape2D = paddle_cs.shape as RectangleShape2D
			var half_h: float = rect.size.y * 0.5

			var relative: float = clamp((global_position.y - collider.global_position.y) / half_h, -1.0, 1.0)
			var new_dir_x: float = (-1.0 if velocity.x > 0.0 else 1.0)
			var bounce_ang: float = relative * deg_to_rad(60.0)
			var new_speed: float = min(velocity.length() + speed_increment, max_speed)

			velocity = Vector2(new_dir_x, 0.0).rotated(bounce_ang).normalized() * new_speed
		else:
			# Top/bottom wall bounce
			emit_signal("wall_hit")
			velocity = velocity.bounce(collision.get_normal())

		var remainder: Vector2 = collision.get_remainder()
		if remainder.length() > 0.0:
			move_and_collide(remainder)

func _apply_texture_if_any() -> void:
	if ball_texture:
		sprite.texture = ball_texture
		sprite.centered = true
		sprite.position = Vector2.ZERO
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if auto_resize_shape:
			var tex_size: Vector2 = ball_texture.get_size()
			# Use the smaller side so the circle fits entirely within the texture
			var d: float = min(tex_size.x, tex_size.y)
			circle_shape.radius = d * 0.5

func center_ball() -> void:
	global_position = get_viewport_rect().size * 0.5
	velocity = Vector2.ZERO
