class_name LocalRankingTestSuite
extends GdUnitTestSuite

const GAME_SCENE := "res://scenes/game/game.tscn"
const RANKING_PATH := "user://ranking.json"


func before_test() -> void:
	if FileAccess.file_exists(RANKING_PATH):
		DirAccess.remove_absolute(RANKING_PATH)
	SaveManager._ranking = []


func test_save_manager_starts_with_empty_ranking() -> void:
	SaveManager.load_ranking()
	var ranking := SaveManager.get_ranking()

	assert_array(ranking).is_empty()


func test_add_entry_returns_correct_position() -> void:
	var pos_first := SaveManager.add_entry(1000, 50)
	assert_int(pos_first).is_equal(0)

	var pos_higher := SaveManager.add_entry(2000, 80)
	assert_int(pos_higher).is_equal(0)

	var pos_lower := SaveManager.add_entry(500, 30)
	assert_int(pos_lower).is_equal(2)


func test_ranking_sorted_by_score_descending() -> void:
	SaveManager.add_entry(100, 10)
	SaveManager.add_entry(500, 50)
	SaveManager.add_entry(300, 30)

	var ranking := SaveManager.get_ranking()
	assert_int(ranking[0]["score"]).is_equal(500)
	assert_int(ranking[1]["score"]).is_equal(300)
	assert_int(ranking[2]["score"]).is_equal(100)


func test_ranking_caps_at_max_entries() -> void:
	for i in range(12):
		SaveManager.add_entry((i + 1) * 100, (i + 1) * 10)

	var ranking := SaveManager.get_ranking()
	assert_int(ranking.size()).is_equal(SaveManager.MAX_RANKING_ENTRIES)
	assert_int(ranking[0]["score"]).is_equal(1200)
	assert_int(ranking[9]["score"]).is_equal(300)


func test_low_score_not_in_full_ranking_returns_minus_one() -> void:
	for i in range(10):
		SaveManager.add_entry((i + 1) * 1000, (i + 1) * 100)

	var pos := SaveManager.add_entry(1, 1)
	assert_int(pos).is_equal(-1)
	assert_int(SaveManager.get_ranking().size()).is_equal(SaveManager.MAX_RANKING_ENTRIES)


func test_ranking_persists_across_save_load() -> void:
	SaveManager.add_entry(5000, 200)
	SaveManager.add_entry(3000, 150)
	SaveManager.save_ranking()

	SaveManager._ranking = []
	SaveManager.load_ranking()

	var ranking := SaveManager.get_ranking()
	assert_int(ranking.size()).is_equal(2)
	assert_int(ranking[0]["score"]).is_equal(5000)
	assert_int(ranking[1]["score"]).is_equal(3000)


func test_corrupt_file_handled_gracefully() -> void:
	var file := FileAccess.open(RANKING_PATH, FileAccess.WRITE)
	file.store_string("not valid json {{{")
	file = null

	SaveManager.load_ranking()
	var ranking := SaveManager.get_ranking()

	assert_array(ranking).is_empty()


func test_game_over_creates_ranking_entry() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	RunSignals.collectable_collected.emit(null, game.player, 500)
	await runner.simulate_frames(1)

	game.call("_set_game_over")
	await runner.simulate_frames(1)

	var ranking := SaveManager.get_ranking()
	assert_int(ranking.size()).is_greater(0)
	assert_int(ranking[0]["score"]).is_greater(0)


func test_ranking_entry_added_signal_emitted_on_game_over() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	game.call("_start_run")
	await runner.simulate_frames(1)

	game.call("_set_game_over")
	await runner.simulate_frames(2)

	var ranking := SaveManager.get_ranking()
	assert_int(ranking.size()).is_equal(1)

	var hud_label := game.get_node("HUD/GameOverMenu/Panel/VBoxContainer/NewRecordLabel") as Label
	assert_bool(hud_label.visible).is_true()
	assert_str(hud_label.text).contains("#1")


func test_new_record_label_shown_on_game_over() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var new_record_label := game.get_node("HUD/GameOverMenu/Panel/VBoxContainer/NewRecordLabel") as Label
	assert_bool(new_record_label.visible).is_false()

	game.call("_start_run")
	await runner.simulate_frames(1)

	game.call("_set_game_over")
	await runner.simulate_frames(2)

	var ranking := SaveManager.get_ranking()
	assert_int(ranking.size()).is_greater(0)
	assert_bool(new_record_label.visible).is_true()
	assert_str(new_record_label.text).contains("#1")


func test_ranking_button_exists_in_menus() -> void:
	var runner := scene_runner(GAME_SCENE)
	var game := runner.scene() as Game

	assert_object(game).is_not_null()
	await runner.simulate_frames(1)

	var main_menu_ranking := game.get_node("HUD/MainMenu/Panel/VBoxContainer/RankingButton") as Button
	var game_over_ranking := game.get_node("HUD/GameOverMenu/Panel/VBoxContainer/RankingButton") as Button
	var local_ranking_menu := game.get_node("HUD/LocalRankingMenu") as Control

	assert_object(main_menu_ranking).is_not_null()
	assert_object(game_over_ranking).is_not_null()
	assert_object(local_ranking_menu).is_not_null()
	assert_bool(local_ranking_menu.visible).is_false()
