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


func test_chunk_manager_starts_in_laboratory_scenario() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager
	var first_chunk := chunks.get_child(0) as Node2D

	assert_str(String(chunks.active_scenario_id)).is_equal("laboratory")
	assert_bool(first_chunk.name.begins_with("LabChunk")).is_true()


func test_chunk_manager_switches_future_chunks_after_transition_score() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager

	RunSignals.score_changed.emit(Balance.config.transition_score)
	await runner.simulate_frames(1)

	assert_str(String(chunks.active_scenario_id)).is_equal("default")

	var first_chunk := chunks.get_child(0) as Node2D
	first_chunk.position.x = -chunks.chunk_width - chunks.recycle_buffer_px - 10.0
	chunks.call("_recycle_offscreen_chunks")
	chunks.call("_ensure_chunk_buffer")
	await runner.simulate_frames(1)

	var newest_chunk := chunks.get_child(chunks.get_child_count() - 1) as Node2D
	assert_bool(newest_chunk.name.begins_with("LabChunk")).is_false()
	assert_bool(newest_chunk.name.begins_with("Chunk")).is_true()


func test_chunk_layout_uses_curated_slots_and_scales_platforms_by_speed() -> void:
	const CHUNK_SCENE := "res://scenes/game/chunks/chunk_b.tscn"
	const POINT_SLOTS := [
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
	const BOOST_SLOTS := [
		Vector2(128, 224),
		Vector2(160, 180),
		Vector2(320, 120),
		Vector2(368, 224),
		Vector2(560, 192),
	]
	const HAZARD_SLOTS := [
		Vector2(160, 192),
		Vector2(192, 192),
		Vector2(416, 192),
		Vector2(560, 192),
	]

	var runner := scene_runner(CHUNK_SCENE)
	var chunk := runner.scene() as Node2D

	assert_object(chunk).is_not_null()
	await runner.simulate_frames(1)

	chunk.call("configure_layout", 12345, Balance.config.default_scroll_speed)

	var pill := chunk.get_node("PillCollectable") as Node2D
	var box := chunk.get_node("BoxCollectable") as Node2D
	var speed_up := chunk.get_node("SpeedUpCollectable") as Node2D
	var speed_down := chunk.get_node("SpeedDownCollectable") as Node2D
	var platform := chunk.get_node("Platform") as Node2D

	assert_bool(POINT_SLOTS.has(pill.position)).is_true()
	assert_bool(POINT_SLOTS.has(box.position)).is_true()
	assert_bool(BOOST_SLOTS.has(speed_up.position)).is_true()
	assert_bool(HAZARD_SLOTS.has(speed_down.position)).is_true()

	var base_platform_width := float(platform.get("width"))
	var base_platform_y := platform.position.y

	chunk.call("configure_layout", 12345, Balance.config.late_scroll_speed)

	assert_float(float(platform.get("width"))).is_greater(base_platform_width)
	assert_float(platform.position.y).is_greater(base_platform_y)
