class_name PlayerBehaviorTestSuite
extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_player_jump_requests_follow_state_transitions() -> void:
	var player := preload(PLAYER_SCENE).instantiate() as Player

	assert_object(player).is_not_null()
	assert_int(player.current_state).is_equal(Player.RunState.PAUSED)
	assert_bool(player.request_jump()).is_false()

	player.start_run()
	assert_int(player.current_state).is_equal(Player.RunState.RUNNING)
	player.velocity = Vector2(123.0, 45.0)
	assert_bool(player.request_jump()).is_true()

	player.pause_run()
	assert_int(player.current_state).is_equal(Player.RunState.PAUSED)
	assert_float(player.velocity.x).is_equal(0.0)
	assert_bool(player.request_jump()).is_false()

	player.end_run()
	assert_int(player.current_state).is_equal(Player.RunState.DEAD)
	assert_bool(player.request_jump()).is_false()
