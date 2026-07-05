class_name ChunkManagerBehaviorTestSuite
extends GdUnitTestSuite

const GAME_SCENE := "res://scenes/game/game.tscn"


func test_chunk_manager_spawns_buffer_and_recycles_offscreen_chunks() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager
	assert_object(chunks).is_not_null()

	var viewport_width := float(chunks.call("_get_viewport_width"))
	var right_edge := float(chunks.call("_get_rightmost_edge"))
	assert_bool(right_edge >= viewport_width + chunks.spawn_buffer_px).is_true()
	assert_bool(chunks.get_child_count() >= chunks.initial_chunk_count).is_true()

	var first_chunk := chunks.get_child(0) as Node2D
	first_chunk.position.x = -chunks.chunk_width - chunks.recycle_buffer_px - 10.0
	chunks.call("_recycle_offscreen_chunks")
	chunks.call("_ensure_chunk_buffer")
	await runner.simulate_frames(1)

	assert_bool(is_instance_valid(first_chunk)).is_false()
	var right_edge_after := float(chunks.call("_get_rightmost_edge"))
	assert_bool(right_edge_after >= viewport_width + chunks.spawn_buffer_px).is_true()


func test_chunk_manager_starts_in_laboratory_scenario_with_opening_pattern() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager
	var first_chunk := chunks.get_child(0) as Node2D

	assert_str(String(chunks.active_scenario_id)).is_equal("laboratory")
	assert_bool(first_chunk.name.begins_with("LabChunk")).is_true()
	assert_str(String(first_chunk.get_meta("scenario_id"))).is_equal("laboratory")
	assert_str(String(first_chunk.get_meta("spawn_pattern_id"))).is_equal("lab_opening_pattern")
	assert_object(first_chunk.find_child("PillCollectable", true, false)).is_not_null()
	assert_object(first_chunk.find_child("BoxCollectable", true, false)).is_not_null()
	assert_object(first_chunk.find_child("SpeedUpCollectable", true, false)).is_not_null()


func test_chunk_manager_switches_future_chunks_after_scenario_transition() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager

	RunSignals.score_changed.emit(20000)
	await runner.simulate_frames(1)

	assert_str(String(chunks.active_scenario_id)).is_equal("default")

	var first_chunk := chunks.get_child(0) as Node2D
	first_chunk.position.x = -chunks.chunk_width - chunks.recycle_buffer_px - 10.0
	chunks.call("_recycle_offscreen_chunks")
	chunks.call("_ensure_chunk_buffer")
	await runner.simulate_frames(1)

	var newest_chunk := chunks.get_child(chunks.get_child_count() - 1) as Node2D
	assert_bool(newest_chunk.name.begins_with("Chunk")).is_true()
	assert_str(String(newest_chunk.get_meta("scenario_id"))).is_equal("default")
	assert_str(String(newest_chunk.get_meta("spawn_pattern_id"))).is_equal("city_transition_pattern")
	assert_object(newest_chunk.find_child("Obstacle", true, false)).is_not_null()
	assert_object(newest_chunk.find_child("SpeedDownCollectable", true, false)).is_not_null()
