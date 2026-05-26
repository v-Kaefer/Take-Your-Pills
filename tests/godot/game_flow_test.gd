class_name GameFlowTestSuite
extends GdUnitTestSuite

const GAME_SCENE := "res://scenes/game/game.tscn"


func test_game_boot_pause_game_over_and_restart_prompt() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager
	var player := game.get_node("World/Player") as Player
	var restart_button := game.get_node("HUD/MarginContainer/VBoxContainer/RestartButton") as Button
	var state_label := game.get_node("HUD/MarginContainer/VBoxContainer/StateLabel") as Label

	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_int(player.current_state).is_equal(Player.RunState.RUNNING)
	assert_bool(chunks.scrolling_enabled).is_true()
	assert_bool(restart_button.visible).is_false()
	assert_str(state_label.text).contains("State: RUNNING")

	game.call("_toggle_pause")
	assert_int(game.current_state).is_equal(Game.GameState.PAUSED)
	assert_int(player.current_state).is_equal(Player.RunState.PAUSED)
	assert_bool(chunks.scrolling_enabled).is_false()
	assert_str(state_label.text).contains("State: PAUSED")

	game.call("_toggle_pause")
	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_int(player.current_state).is_equal(Player.RunState.RUNNING)
	assert_bool(chunks.scrolling_enabled).is_true()

	game.call("_set_game_over")
	assert_int(game.current_state).is_equal(Game.GameState.GAME_OVER)
	assert_int(player.current_state).is_equal(Player.RunState.DEAD)
	assert_bool(restart_button.visible).is_true()
	assert_str(state_label.text).contains("State: GAME OVER")
	assert_str(state_label.text).contains("Jump: restart")
	assert_str(state_label.text).contains("Restart: button")
