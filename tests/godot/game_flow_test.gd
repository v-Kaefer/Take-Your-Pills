class_name GameFlowTestSuite
extends GdUnitTestSuite

const GAME_SCENE := "res://scenes/game/game.tscn"


func test_game_boots_in_main_menu_state() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var player := game.get_node("World/Player") as Player
	var chunks := game.get_node("World/Chunks") as ChunkManager
	var main_menu := game.get_node("HUD/MainMenu") as Control
	var pause_menu := game.get_node("HUD/PauseMenu") as Control
	var game_over_menu := game.get_node("HUD/GameOverMenu") as Control

	assert_int(game.current_state).is_equal(Game.GameState.MAIN_MENU)
	assert_int(player.current_state).is_equal(Player.RunState.PAUSED)
	assert_bool(chunks.scrolling_enabled).is_false()
	assert_bool(main_menu.visible).is_true()
	assert_bool(pause_menu.visible).is_false()
	assert_bool(game_over_menu.visible).is_false()


func test_start_transitions_to_running_state() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var player := game.get_node("World/Player") as Player
	var chunks := game.get_node("World/Chunks") as ChunkManager
	var main_menu := game.get_node("HUD/MainMenu") as Control
	var state_label := game.get_node("HUD/MarginContainer/VBoxContainer/StateLabel") as Label
	var start_button := game.get_node("HUD/MainMenu/Panel/VBoxContainer/StartButton") as Button

	start_button.emit_signal("pressed")
	await runner.simulate_frames(1)

	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_int(player.current_state).is_equal(Player.RunState.RUNNING)
	assert_bool(chunks.scrolling_enabled).is_true()
	assert_bool(main_menu.visible).is_false()
	assert_str(state_label.text).contains("State: RUNNING")


func test_collectable_score_persists_after_next_frame() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var baseline_score := game.score
	RunSignals.collectable_collected.emit(null, game.player, 100)
	await runner.simulate_frames(1)

	var score_after_collect := game.score

	assert_int(score_after_collect).is_greater(baseline_score)

	await runner.simulate_frames(1)

	assert_int(game.score).is_greater_equal(score_after_collect)


func test_pause_and_resume_from_running_state() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var player := game.get_node("World/Player") as Player
	var chunks := game.get_node("World/Chunks") as ChunkManager
	var pause_menu := game.get_node("HUD/PauseMenu") as Control
	var state_label := game.get_node("HUD/MarginContainer/VBoxContainer/StateLabel") as Label

	game.call("_toggle_pause")
	assert_int(game.current_state).is_equal(Game.GameState.PAUSED)
	assert_int(player.current_state).is_equal(Player.RunState.PAUSED)
	assert_bool(chunks.scrolling_enabled).is_false()
	assert_bool(pause_menu.visible).is_true()
	assert_str(state_label.text).contains("State: PAUSED")

	game.call("_toggle_pause")
	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_int(player.current_state).is_equal(Player.RunState.RUNNING)
	assert_bool(chunks.scrolling_enabled).is_true()
	assert_bool(pause_menu.visible).is_false()


func test_game_over_shows_game_over_menu() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var game_over_menu := game.get_node("HUD/GameOverMenu") as Control
	var restart_button := game.get_node("HUD/GameOverMenu/Panel/VBoxContainer/RestartButton") as Button
	var state_label := game.get_node("HUD/MarginContainer/VBoxContainer/StateLabel") as Label

	game.call("_set_game_over")
	assert_int(game.current_state).is_equal(Game.GameState.GAME_OVER)
	assert_bool(game_over_menu.visible).is_true()
	assert_bool(restart_button.visible).is_true()
	assert_str(state_label.text).contains("State: GAME OVER")
	assert_str(state_label.text).contains("Jump: restart")
	assert_str(state_label.text).contains("Restart: button")
