extends Node2D
class_name ChunkManager

const CHUNK_SCENES: Array[PackedScene] = [
	preload("res://scenes/game/chunks/chunk_a.tscn"),
	preload("res://scenes/game/chunks/chunk_b.tscn"),
	preload("res://scenes/game/chunks/chunk_c.tscn"),
]

@export var scroll_speed: float = 240.0
@export var chunk_width: float = 640.0
@export var initial_chunk_count: int = 3

var scrolling_enabled: bool = false
var _active_chunks: Array[Node2D] = []
var _spawn_cursor: int = 0


func _ready() -> void:
	RunSignals.request_next_chunk.connect(_on_request_next_chunk)
	RunSignals.chunk_exited_screen.connect(_on_chunk_exited_screen)
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
	for index in range(initial_chunk_count):
		_spawn_chunk(Vector2(chunk_width * index, 0.0))


func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(value, 0.0)


func _physics_process(delta: float) -> void:
	if not scrolling_enabled:
		return

	var displacement := scroll_speed * delta
	for chunk in _active_chunks:
		chunk.position.x -= displacement


func _on_request_next_chunk(chunk: Node) -> void:
	if not scrolling_enabled:
		return

	if _active_chunks.is_empty():
		return

	var tail_chunk := _get_tail_chunk()
	if chunk != tail_chunk:
		return

	call_deferred("_spawn_chunk", Vector2(_get_rightmost_x() + chunk_width, 0.0))


func _on_chunk_exited_screen(chunk: Node) -> void:
	var typed_chunk := chunk as Node2D
	if typed_chunk == null:
		return

	if _active_chunks.has(typed_chunk):
		_active_chunks.erase(typed_chunk)
		typed_chunk.queue_free()


func _spawn_chunk(spawn_position: Vector2) -> void:
	if CHUNK_SCENES.is_empty():
		return

	var scene_index := _spawn_cursor % CHUNK_SCENES.size()
	var chunk := CHUNK_SCENES[scene_index].instantiate() as Node2D
	_spawn_cursor += 1
	chunk.position = spawn_position
	add_child(chunk)
	_active_chunks.append(chunk)


func _clear_chunks() -> void:
	for chunk in _active_chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()

	_active_chunks.clear()


func _get_tail_chunk() -> Node2D:
	if _active_chunks.is_empty():
		return null

	var tail_chunk := _active_chunks[0]
	for chunk in _active_chunks:
		if chunk.position.x > tail_chunk.position.x:
			tail_chunk = chunk

	return tail_chunk


func _get_rightmost_x() -> float:
	if _active_chunks.is_empty():
		return 0.0

	var rightmost_x := _active_chunks[0].position.x
	for chunk in _active_chunks:
		if chunk.position.x > rightmost_x:
			rightmost_x = chunk.position.x

	return rightmost_x
