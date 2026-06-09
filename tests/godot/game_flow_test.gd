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
	var session_controller := game.get_node("Controllers/RunSessionController")
	var score_controller := game.get_node("Controllers/RunScoreController")
	var audio_controller := game.get_node("Controllers/CollectableAudioController")
	var main_menu := game.get_node("HUD/MainMenu") as Control
	var pause_menu := game.get_node("HUD/PauseMenu") as Control
	var game_over_menu := game.get_node("HUD/GameOverMenu") as Control

	assert_int(game.current_state).is_equal(Game.GameState.MAIN_MENU)
	assert_int(player.current_state).is_equal(Player.RunState.PAUSED)
	assert_bool(chunks.scrolling_enabled).is_false()
	assert_object(session_controller).is_not_null()
	assert_object(score_controller).is_not_null()
	assert_object(audio_controller).is_not_null()
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


func test_speed_hud_rows_bind_to_matching_collectables() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var speed_container := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer") as VBoxContainer
	var speed_up_icon := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedUpContainer/SpeedUpIcon") as TextureRect
	var speed_down_icon := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedDownContainer/SpeedDownIcon") as TextureRect
	var speed_up_stripes := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedUpContainer/SpeedUpStripes") as HBoxContainer
	var speed_down_stripes := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedDownContainer/SpeedDownStripes") as HBoxContainer
	var boost_timer_label := game.get_node("HUD/BoostTimerLabel") as Label
	var speed_up_first_stripe := speed_up_stripes.get_child(0) as ColorRect
	var speed_down_first_stripe := speed_down_stripes.get_child(0) as ColorRect
	var speed_up_initial_color := speed_up_first_stripe.color
	var speed_down_initial_color := speed_down_first_stripe.color

	assert_str((speed_container.get_child(0) as Control).name).is_equal("SpeedUpContainer")
	assert_str((speed_container.get_child(1) as Control).name).is_equal("SpeedDownContainer")
	assert_object(speed_up_icon.texture).is_not_null()
	assert_object(speed_down_icon.texture).is_not_null()
	assert_str(speed_up_icon.texture.resource_path).contains("asset_speed_up")
	assert_str(speed_down_icon.texture.resource_path).contains("asset_speed_down")
	assert_bool(boost_timer_label.visible).is_false()

	RunSignals.speed_up_collected.emit()
	assert_float(speed_up_first_stripe.color.b).is_greater(speed_up_first_stripe.color.r)
	assert_float(speed_down_first_stripe.color.r).is_equal(speed_down_initial_color.r)
	assert_float(speed_down_first_stripe.color.g).is_equal(speed_down_initial_color.g)
	assert_float(speed_down_first_stripe.color.b).is_equal(speed_down_initial_color.b)
	assert_bool(boost_timer_label.visible).is_false()

	RunSignals.speed_up_collected.emit()
	assert_float(speed_up_first_stripe.color.b).is_greater(speed_up_first_stripe.color.r)
	assert_bool(boost_timer_label.visible).is_false()

	RunSignals.speed_up_collected.emit()
	assert_float(speed_up_first_stripe.color.r).is_equal(speed_up_initial_color.r)
	assert_float(speed_up_first_stripe.color.g).is_equal(speed_up_initial_color.g)
	assert_float(speed_up_first_stripe.color.b).is_equal(speed_up_initial_color.b)
	assert_float(speed_up_first_stripe.color.a).is_equal(speed_up_initial_color.a)
	assert_bool(boost_timer_label.visible).is_true()
	assert_str(boost_timer_label.text).contains("Boost:")
	assert_str(boost_timer_label.text).contains("8.0")

	var speed_up_after_reset := speed_up_first_stripe.color

	RunSignals.speed_down_collected.emit()
	RunSignals.speed_down_collected.emit()
	assert_float(speed_down_first_stripe.color.r).is_greater(speed_down_first_stripe.color.b)
	assert_float(speed_up_first_stripe.color.r).is_equal(speed_up_after_reset.r)
	assert_float(speed_up_first_stripe.color.g).is_equal(speed_up_after_reset.g)
	assert_float(speed_up_first_stripe.color.b).is_equal(speed_up_after_reset.b)

	RunSignals.speed_down_collected.emit()
	assert_float(speed_down_first_stripe.color.r).is_equal(speed_down_initial_color.r)
	assert_float(speed_down_first_stripe.color.g).is_equal(speed_down_initial_color.g)
	assert_float(speed_down_first_stripe.color.b).is_equal(speed_down_initial_color.b)
	assert_float(speed_down_first_stripe.color.a).is_equal(speed_down_initial_color.a)
	assert_float(speed_up_first_stripe.color.r).is_equal(speed_up_after_reset.r)
	assert_float(speed_up_first_stripe.color.g).is_equal(speed_up_after_reset.g)
	assert_float(speed_up_first_stripe.color.b).is_equal(speed_up_after_reset.b)


func test_speed_up_collects_stack_boost_and_extend_latest_timer() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager
	var controller := game.get_node("Controllers/SpeedUpBoostController")
	var boost_timer_label := game.get_node("HUD/BoostTimerLabel") as Label
	var speed_up_icon := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedUpContainer/SpeedUpIcon") as TextureRect
	var speed_up_stripes := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedUpContainer/SpeedUpStripes") as HBoxContainer
	var speed_up_first_stripe := speed_up_stripes.get_child(0) as ColorRect
	var initial_speed_up_color := speed_up_first_stripe.color

	RunSignals.speed_up_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED)
	assert_object(speed_up_icon.texture).is_not_null()
	assert_float(speed_up_first_stripe.color.b).is_greater(speed_up_first_stripe.color.r)
	assert_float(speed_up_first_stripe.color.b).is_greater(initial_speed_up_color.b)
	assert_bool(boost_timer_label.visible).is_false()

	RunSignals.speed_up_collected.emit()
	RunSignals.speed_up_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 1.5)
	assert_float(speed_up_first_stripe.color.r).is_equal(initial_speed_up_color.r)
	assert_float(speed_up_first_stripe.color.g).is_equal(initial_speed_up_color.g)
	assert_float(speed_up_first_stripe.color.b).is_equal(initial_speed_up_color.b)
	assert_bool(boost_timer_label.visible).is_true()
	assert_str(boost_timer_label.text).contains("Boost:")
	assert_str(boost_timer_label.text).contains("8.0")

	controller.tick(4.0)
	RunSignals.speed_up_collected.emit()
	RunSignals.speed_up_collected.emit()
	RunSignals.speed_up_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 2.0)
	assert_float(speed_up_first_stripe.color.r).is_equal(initial_speed_up_color.r)
	assert_float(speed_up_first_stripe.color.g).is_equal(initial_speed_up_color.g)
	assert_float(speed_up_first_stripe.color.b).is_equal(initial_speed_up_color.b)
	assert_bool(boost_timer_label.visible).is_true()
	assert_str(boost_timer_label.text).contains("10.0")

	controller.tick(5.9)
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 2.0)
	assert_bool(boost_timer_label.visible).is_true()

	controller.tick(4.2)
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED)
	assert_bool(boost_timer_label.visible).is_false()
	assert_float(speed_up_first_stripe.color.r).is_equal(initial_speed_up_color.r)
	assert_float(speed_up_first_stripe.color.g).is_equal(initial_speed_up_color.g)
	assert_float(speed_up_first_stripe.color.b).is_equal(initial_speed_up_color.b)


func test_speed_down_collects_queue_until_boost_ends() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	var chunks := game.get_node("World/Chunks") as ChunkManager
	var controller := game.get_node("Controllers/SpeedUpBoostController")
	var boost_timer_label := game.get_node("HUD/BoostTimerLabel") as Label
	var speed_down_stripes := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedDownContainer/SpeedDownStripes") as HBoxContainer
	var speed_down_first_stripe := speed_down_stripes.get_child(0) as ColorRect
	var speed_down_initial_color := speed_down_first_stripe.color

	RunSignals.speed_up_collected.emit()
	RunSignals.speed_up_collected.emit()
	RunSignals.speed_up_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 1.5)
	assert_bool(boost_timer_label.visible).is_true()
	assert_float(speed_down_first_stripe.color.r).is_equal(speed_down_initial_color.r)
	assert_float(speed_down_first_stripe.color.g).is_equal(speed_down_initial_color.g)
	assert_float(speed_down_first_stripe.color.b).is_equal(speed_down_initial_color.b)

	RunSignals.speed_down_collected.emit()
	RunSignals.speed_down_collected.emit()
	RunSignals.speed_down_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 1.5)
	assert_float(speed_down_first_stripe.color.r).is_equal(speed_down_initial_color.r)
	assert_float(speed_down_first_stripe.color.g).is_equal(speed_down_initial_color.g)
	assert_float(speed_down_first_stripe.color.b).is_equal(speed_down_initial_color.b)

	controller.tick(8.1)
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 0.75)
	assert_bool(boost_timer_label.visible).is_false()


func test_speed_down_collects_apply_only_after_three_picks_and_finish_the_run_at_extreme_slow() -> void:
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
	var speed_down_icon := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedDownContainer/SpeedDownIcon") as TextureRect
	var speed_down_stripes := game.get_node("HUD/MarginContainer/VBoxContainer/SpeedContainer/SpeedDownContainer/SpeedDownStripes") as HBoxContainer
	var speed_down_first_stripe := speed_down_stripes.get_child(0) as ColorRect
	var speed_down_initial_color := speed_down_first_stripe.color

	RunSignals.speed_down_collected.emit()
	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED)
	assert_object(speed_down_icon.texture).is_not_null()
	assert_float(speed_down_first_stripe.color.r).is_greater(speed_down_first_stripe.color.b)

	RunSignals.speed_down_collected.emit()
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED)
	assert_float(speed_down_first_stripe.color.r).is_greater(speed_down_first_stripe.color.b)

	RunSignals.speed_down_collected.emit()
	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 0.75)
	assert_float(speed_down_first_stripe.color.r).is_equal(speed_down_initial_color.r)
	assert_float(speed_down_first_stripe.color.g).is_equal(speed_down_initial_color.g)
	assert_float(speed_down_first_stripe.color.b).is_equal(speed_down_initial_color.b)

	RunSignals.speed_down_collected.emit()
	assert_float(speed_down_first_stripe.color.r).is_greater(speed_down_first_stripe.color.b)
	RunSignals.speed_down_collected.emit()
	assert_float(speed_down_first_stripe.color.r).is_greater(speed_down_first_stripe.color.b)
	RunSignals.speed_down_collected.emit()
	assert_int(game.current_state).is_equal(Game.GameState.RUNNING)
	assert_float(chunks.scroll_speed).is_equal(Game.DEFAULT_SCROLL_SPEED * 0.5)
	assert_float(speed_down_first_stripe.color.r).is_equal(speed_down_initial_color.r)
	assert_float(speed_down_first_stripe.color.g).is_equal(speed_down_initial_color.g)
	assert_float(speed_down_first_stripe.color.b).is_equal(speed_down_initial_color.b)

	RunSignals.speed_down_collected.emit()
	RunSignals.speed_down_collected.emit()
	RunSignals.speed_down_collected.emit()
	assert_int(game.current_state).is_equal(Game.GameState.GAME_OVER)
	assert_int(player.current_state).is_equal(Player.RunState.DEAD)
	assert_bool(game_over_menu.visible).is_true()
	assert_str(state_label.text).contains("State: GAME OVER")
	assert_str(state_label.text).contains("Jump: restart")
