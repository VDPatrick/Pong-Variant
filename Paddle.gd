extends CharacterBody2D

@export var speed: float = 480.0
@export var up_action: StringName = &"p1_up"   # Set per paddle in the Inspector
@export var down_action: StringName = &"p1_down"

# Drag a PNG here in the Inspector. If auto_resize_shape = true, the collision box will match the texture size.
@export var paddle_texture: Texture2D
@export var auto_resize_shape: bool = true

@onready var shape: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
@onready var sprite: Sprite2D = $Sprite2D

const TOP_MARGIN := 16.0
const BOTTOM_MARGIN := 16.0
const WINDOW_H := 768.0

func _ready() -> void:
	add_to_group(&"paddle")
	_apply_texture_if_any()

func _physics_process(delta: float) -> void:
	var dir: float = 0.0
	if Input.is_action_pressed(up_action):
		dir -= 1.0
	if Input.is_action_pressed(down_action):
		dir += 1.0

	position.y += dir * speed * delta

	var half_h: float = shape.size.y * 0.5
	position.y = clamp(position.y, TOP_MARGIN + half_h, WINDOW_H - BOTTOM_MARGIN - half_h)

func _apply_texture_if_any() -> void:
	if paddle_texture:
		sprite.texture = paddle_texture
		sprite.centered = true
		sprite.position = Vector2.ZERO
		# Optional for crisp pixels
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if auto_resize_shape:
			var sz: Vector2 = paddle_texture.get_size()
			shape.size = sz
