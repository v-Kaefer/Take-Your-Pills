extends Node2D
class_name ChunkManager

const CHUNK_SCENES: Array[PackedScene] = [
	preload("res://scenes/game/chunks/chunk_a.tscn"),
	preload("res://scenes/game/chunks/chunk_b.tscn"),
	preload("res://scenes/game/chunks/chunk_c.tscn"),
]

@export var scroll_speed: float = 240.0
@export var chunk_width: float = 640.0
@export var chunk_overlap_px: float = 32.0
@export var spawn_buffer_px: float = 256.0
@export var recycle_buffer_px: float = 128.0
@export var initial_chunk_count: int = 3

var scrolling_enabled: bool = false
var _active_chunks: Array[Node2D] = []
var _spawn_cursor: int = 0


func _ready() -> void:
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
	_clear_chunks()
	var chunk_count: int = initial_chunk_count
	var required_chunks: int = _required_initial_chunks()
	if required_chunks > chunk_count:
		chunk_count = required_chunks
	for index in range(chunk_count):
		_spawn_chunk(Vector2(chunk_width * index, 0.0))
	_ensure_chunk_buffer()


func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(value, 0.0)


func _physics_process(delta: float) -> void:
	if not scrolling_enabled:
		return

	var displacement := scroll_speed * delta
	for chunk in _active_chunks:
		chunk.position.x -= displacement

	_recycle_offscreen_chunks()
	_ensure_chunk_buffer()


func _spawn_chunk(spawn_position: Vector2) -> void:
	if CHUNK_SCENES.is_empty():
		return

	var scene_index := _spawn_cursor % CHUNK_SCENES.size()
	var chunk := CHUNK_SCENES[scene_index].instantiate() as Node2D
	_spawn_cursor += 1
	chunk.position = spawn_position
	add_child(chunk)
	_active_chunks.append(chunk)


func _ensure_chunk_buffer() -> void:
	if CHUNK_SCENES.is_empty():
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
