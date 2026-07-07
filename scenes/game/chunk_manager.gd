extends Node2D
class_name ChunkManager

@export var scroll_speed: float = 240.0
@export var chunk_width: float = 640.0
@export var chunk_overlap_px: float = 32.0
@export var spawn_buffer_px: float = 256.0
@export var recycle_buffer_px: float = 128.0
@export var initial_chunk_count: int = 3
@export var starting_scenario_id: StringName = &"laboratory"
@export var laboratory_chunk_scenes: Array[PackedScene] = []
@export var default_chunk_scenes: Array[PackedScene] = []

var scrolling_enabled: bool = false
var active_scenario_id: StringName = &"laboratory"
var active_chunk_scenes: Array[PackedScene] = []
var _spawn_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_order: Array[int] = []
var _spawn_order_cursor: int = 0
var _active_chunks: Array[Node2D] = []
var _spawn_cursor: int = 0
var _last_spawn_scene_index: int = -1


func _ready() -> void:
	if Balance != null and Balance.config != null:
		scroll_speed = Balance.config.default_scroll_speed
	_spawn_rng.randomize()
	reset_run()


func start_run() -> void:
	scrolling_enabled = true


func pause_run() -> void:
	scrolling_enabled = false


func end_run() -> void:
	scrolling_enabled = false


func reset_run() -> void:
	scrolling_enabled = false
	_spawn_cursor = 0
	_set_active_scenario(starting_scenario_id)
	_rebuild_spawn_order()
	_clear_chunks()
	var chunk_count: int = initial_chunk_count
	var required_chunks: int = _required_initial_chunks()
	if required_chunks > chunk_count:
		chunk_count = required_chunks
	for index in range(chunk_count):
		_spawn_chunk(Vector2(chunk_width * index, 0.0))
	_ensure_chunk_buffer()
	RunSignals.scenario_changed.emit(active_scenario_id)


func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(value, 0.0)


func switch_to_scenario(scenario_id: StringName) -> void:
	if scenario_id == active_scenario_id:
		return

	_set_active_scenario(scenario_id)
	_rebuild_spawn_order()
	RunSignals.scenario_changed.emit(active_scenario_id)


func _physics_process(delta: float) -> void:
	if not scrolling_enabled:
		return

	var displacement := scroll_speed * delta
	for chunk in _active_chunks:
		chunk.position.x -= displacement

	_recycle_offscreen_chunks()
	_ensure_chunk_buffer()


func _spawn_chunk(spawn_position: Vector2) -> void:
	var chunk_scene := _next_chunk_scene()
	if chunk_scene == null:
		return

	var layout_seed := int(_spawn_rng.randi()) ^ _spawn_cursor
	var chunk := chunk_scene.instantiate() as Node2D
	_spawn_cursor += 1
	chunk.position = spawn_position
	add_child(chunk)
	_active_chunks.append(chunk)

	if chunk is Chunk:
		(chunk as Chunk).configure_layout(layout_seed, scroll_speed)


func _ensure_chunk_buffer() -> void:
	if active_chunk_scenes.is_empty():
		return

	var viewport_width := _get_viewport_width()
	var right_edge_limit := viewport_width + spawn_buffer_px
	while _get_rightmost_edge() < right_edge_limit:
		_spawn_chunk(Vector2(_get_rightmost_edge() - chunk_overlap_px, 0.0))


func _recycle_offscreen_chunks() -> void:
	var to_remove: Array[Node2D] = []
	for chunk in _active_chunks:
		if chunk.position.x + chunk_width < -recycle_buffer_px:
			to_remove.append(chunk)

	for chunk in to_remove:
		_active_chunks.erase(chunk)
		if is_instance_valid(chunk):
			chunk.queue_free()


func _clear_chunks() -> void:
	for chunk in _active_chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()

	_active_chunks.clear()


func _get_rightmost_edge() -> float:
	if _active_chunks.is_empty():
		return 0.0

	var rightmost_x := _active_chunks[0].position.x + chunk_width
	for chunk in _active_chunks:
		var chunk_edge := chunk.position.x + chunk_width
		if chunk_edge > rightmost_x:
			rightmost_x = chunk_edge

	return rightmost_x


func _get_viewport_width() -> float:
	var viewport := get_viewport()
	if viewport == null:
		return chunk_width * float(initial_chunk_count)

	return viewport.get_visible_rect().size.x


func _required_initial_chunks() -> int:
	var viewport_width := _get_viewport_width()
	var required_width := viewport_width + spawn_buffer_px
	return int(ceil(required_width / chunk_width)) + 1


func _set_active_scenario(scenario_id: StringName) -> void:
	active_scenario_id = scenario_id
	_last_spawn_scene_index = -1
	if active_scenario_id == &"laboratory":
		active_chunk_scenes = laboratory_chunk_scenes.duplicate()
		if not active_chunk_scenes.is_empty():
			return

	active_chunk_scenes = default_chunk_scenes.duplicate()


func _rebuild_spawn_order() -> void:
	_spawn_order.clear()
	_spawn_order_cursor = 0

	for index in range(active_chunk_scenes.size()):
		_spawn_order.append(index)

	if _spawn_order.size() <= 1:
		return

	for index in range(_spawn_order.size() - 1, 0, -1):
		var swap_index := _spawn_rng.randi_range(0, index)
		var temp := _spawn_order[index]
		_spawn_order[index] = _spawn_order[swap_index]
		_spawn_order[swap_index] = temp

	if _last_spawn_scene_index >= 0 and _spawn_order[0] == _last_spawn_scene_index:
		var swap_index := _spawn_rng.randi_range(1, _spawn_order.size() - 1)
		var temp := _spawn_order[0]
		_spawn_order[0] = _spawn_order[swap_index]
		_spawn_order[swap_index] = temp


func _next_chunk_scene() -> PackedScene:
	if active_chunk_scenes.is_empty():
		return null

	if _spawn_order_cursor >= _spawn_order.size():
		_rebuild_spawn_order()

	if _spawn_order.is_empty():
		return null

	var scene_index := _spawn_order[_spawn_order_cursor]
	_spawn_order_cursor += 1
	_last_spawn_scene_index = scene_index
	return active_chunk_scenes[scene_index]
