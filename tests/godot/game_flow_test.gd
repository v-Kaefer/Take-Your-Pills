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


func test_speed_up_collects_trigger_boost_and_recover() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager
	var controller := game.get_node("Controllers/AdverseStateController")
	var speed_icon := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedIcon") as TextureRect
	var stripes := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/Stripes") as HBoxContainer
	var first_stripe := stripes.get_child(0) as ColorRect

	RunSignals.speed_up_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED)
	assert_object(speed_icon.texture).is_not_null()
	assert_float(first_stripe.color.b).is_greater(first_stripe.color.r)

	RunSignals.speed_up_collected.emit()
	RunSignals.speed_up_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 1.5)
	assert_float(first_stripe.color.r).is_greater(first_stripe.color.b)

	controller.tick(8.1)
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED)
	assert_float(first_stripe.color.b).is_greater(first_stripe.color.r)


func test_speed_down_collects_end_the_run_when_too_slow() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var player := game.get_node("World/Player") as Player
	var chunks := game.get_node("World/Chunks") as ChunkManager
	var game_over_menu := game.get_node("HUD/GameOverMenu") as Control
	var state_label := game.get_node("HUD/MarginContainer/VBoxContainer/StateLabel") as Label
	var stripes := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/Stripes") as HBoxContainer
	var first_stripe := stripes.get_child(0) as ColorRect

	RunSignals.speed_down_collected.emit()
	var speed_after_first_down := chunks.scroll_speed
	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_float(speed_after_first_down).is_less(Game.DEFAULT_SCROLL_SPEED)
	assert_float(first_stripe.color.r).is_greater(first_stripe.color.b)

	RunSignals.speed_down_collected.emit()
	assert_float(chunks.scroll_speed).is_less(speed_after_first_down)

	RunSignals.speed_down_collected.emit()
	assert_int(game.current_state).is_equal(Game.GameState.GAME_OVER)
	assert_int(player.current_state).is_equal(Player.RunState.DEAD)
	assert_bool(game_over_menu.visible).is_true()
	assert_str(state_label.text).contains("State: GAME OVER")
	assert_str(state_label.text).contains("Jump: restart")
