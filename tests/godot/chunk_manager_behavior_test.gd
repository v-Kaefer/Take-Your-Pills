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
	await runner.simulate_frames(1)

	assert_bool(is_instance_valid(first_chunk)).is_false()
	assert_bool(chunks.get_child_count() >= chunks.initial_chunk_count).is_true()
