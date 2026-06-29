@tool
extends StaticBody2D
class_name Platform

@export var width: float = 120.0:
	set(val):
		width = val
		_update_platform()

@export var height: float = 16.0:
	set(val):
		height = val
		_update_platform()

@export var one_way: bool = true:
	set(val):
		one_way = val
		_update_platform()

@export var color: Color = Color(0.18, 0.20, 0.28, 1):
	set(val):
		color = val
		_update_platform()

@export var stripe_color: Color = Color(0.31, 0.78, 0.86, 1):
	set(val):
		stripe_color = val
		_update_platform()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual
@onready var stripe: Polygon2D = $Stripe


func _ready() -> void:
	_update_platform()


func _update_platform() -> void:
	if not is_inside_tree():
		return

	# Configure collision layer and mask dynamically
	collision_layer = 2  # Ground / Platforms
	collision_mask = 0   # Static body doesn't need to mask anything

	if collision_shape:
		collision_shape.one_way_collision = one_way
		if collision_shape.shape is RectangleShape2D:
			# Ensure shape is unique per instance to allow different widths/heights
			collision_shape.shape = collision_shape.shape.duplicate()
			collision_shape.shape.size = Vector2(width, height)
			collision_shape.position = Vector2(width / 2.0, height / 2.0)

	if visual:
		visual.color = color
		visual.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(width, 0),
			Vector2(width, height),
			Vector2(0, height)
		])

	if stripe:
		var stripe_height = 3.0
		stripe.color = stripe_color
		stripe.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(width, 0),
			Vector2(width, stripe_height),
			Vector2(0, stripe_height)
		])
