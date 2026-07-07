extends Node2D
class_name Chunk

const _POINT_SLOTS: Array[Vector2] = [
	Vector2(128, 224),
	Vector2(150, 180),
	Vector2(192, 180),
	Vector2(224, 224),
	Vector2(256, 185),
	Vector2(288, 224),
	Vector2(320, 180),
	Vector2(416, 130),
	Vector2(512, 224),
	Vector2(560, 224),
]
const _BOOST_SLOTS: Array[Vector2] = [
	Vector2(128, 224),
	Vector2(160, 180),
	Vector2(320, 120),
	Vector2(368, 224),
	Vector2(560, 192),
]
const _HAZARD_SLOTS: Array[Vector2] = [
	Vector2(160, 192),
	Vector2(192, 192),
	Vector2(416, 192),
	Vector2(560, 192),
]
const _BASE_PLATFORM_POSITION_META := &"chunk_base_platform_position"
const _BASE_PLATFORM_WIDTH_META := &"chunk_base_platform_width"

@onready var trigger_next: Area2D = $TriggerNext
@onready var on_screen_notifier: VisibleOnScreenNotifier2D = $OnScreenNotifier

var _requested_next_chunk: bool = false
var _collectable_layout_configured: bool = false


func _ready() -> void:
	trigger_next.body_entered.connect(_on_trigger_next_body_entered)
	on_screen_notifier.screen_exited.connect(_on_screen_exited)

	# Configure collision layer and mask dynamically
	trigger_next.collision_layer = 0
	trigger_next.collision_mask = 1 # Player layer

	var ground_body = get_node_or_null("Terrain/GroundBody")
	if ground_body is StaticBody2D:
		ground_body.collision_layer = 2 # Ground / Platforms
		ground_body.collision_mask = 0


func configure_layout(layout_seed: int, scroll_speed: float) -> void:
	_configure_collectable_layout(layout_seed)
	_configure_platform_layout(scroll_speed)


func _on_trigger_next_body_entered(body: Node) -> void:
	if _requested_next_chunk:
		return

	if body is Player:
		_requested_next_chunk = true
		RunSignals.request_next_chunk.emit(self)


func _on_screen_exited() -> void:
	RunSignals.chunk_exited_screen.emit(self)


func _configure_collectable_layout(layout_seed: int) -> void:
	if _collectable_layout_configured:
		return

	var point_collectables: Array[CollectableBase] = []
	var boost_collectables: Array[CollectableBase] = []
	var hazard_collectables: Array[CollectableBase] = []

	for child in get_children():
		if not child is CollectableBase:
			continue

		var collectable := child as CollectableBase
		match collectable.collectable_type:
			&"speed_up":
				boost_collectables.append(collectable)
			&"speed_down":
				hazard_collectables.append(collectable)
			_:
				point_collectables.append(collectable)

	_assign_collectable_slots(point_collectables, _POINT_SLOTS, layout_seed)
	_assign_collectable_slots(boost_collectables, _BOOST_SLOTS, layout_seed + 1)
	_assign_collectable_slots(hazard_collectables, _HAZARD_SLOTS, layout_seed + 2)
	_collectable_layout_configured = true


func _assign_collectable_slots(collectables: Array[CollectableBase], slots: Array[Vector2], seed: int) -> void:
	if collectables.is_empty() or slots.is_empty():
		return

	var shuffled_slots := _shuffle_slots(slots, seed)
	var slot_count := shuffled_slots.size()
	for index in range(collectables.size()):
		collectables[index].position = shuffled_slots[index % slot_count]


func _shuffle_slots(slots: Array[Vector2], seed: int) -> Array[Vector2]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var shuffled := slots.duplicate()
	for index in range(shuffled.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp: Vector2 = shuffled[index]
		shuffled[index] = shuffled[swap_index]
		shuffled[swap_index] = temp
	return shuffled


func _configure_platform_layout(scroll_speed: float) -> void:
	var platform_band := _get_platform_band(scroll_speed)
	var width_scale := float(platform_band["width_scale"])
	var y_offset := float(platform_band["y_offset"])

	for child in get_children():
		if not child.has_method("_update_platform"):
			continue

		var platform := child as Node2D
		if not platform.has_meta(_BASE_PLATFORM_POSITION_META):
			platform.set_meta(_BASE_PLATFORM_POSITION_META, platform.position)
		if not platform.has_meta(_BASE_PLATFORM_WIDTH_META):
			platform.set_meta(_BASE_PLATFORM_WIDTH_META, float(platform.get("width")))

		var base_position := platform.get_meta(_BASE_PLATFORM_POSITION_META) as Vector2
		var base_width := float(platform.get_meta(_BASE_PLATFORM_WIDTH_META))
		platform.position = base_position + Vector2(0.0, y_offset)
		platform.set("width", base_width * width_scale)


func _get_platform_band(scroll_speed: float) -> Dictionary:
	if scroll_speed >= Balance.config.late_scroll_speed:
		return {
			"width_scale": 1.12,
			"y_offset": 8.0,
		}

	if scroll_speed >= Balance.config.transition_scroll_speed:
		return {
			"width_scale": 1.06,
			"y_offset": 4.0,
		}

	if scroll_speed >= Balance.config.mid_scroll_speed:
		return {
			"width_scale": 1.03,
			"y_offset": 2.0,
		}

	return {
		"width_scale": 1.0,
		"y_offset": 0.0,
	}
