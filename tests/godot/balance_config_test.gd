class_name BalanceConfigTestSuite
extends GdUnitTestSuite


func test_balance_autoload_resolves_valid_config() -> void:
	assert_object(Balance).is_not_null()
	assert_object(Balance.config).is_not_null()
	assert_bool(Balance.config is BalanceConfig).is_true()


func test_speed_multiplier_tiers_are_fully_populated() -> void:
	assert_int(Balance.config.speed_up_multipliers.size()).is_equal(3)
	assert_int(Balance.config.speed_down_multipliers.size()).is_equal(3)


func test_core_pacing_values_are_positive() -> void:
	assert_float(Balance.config.default_scroll_speed).is_greater(0.0)
	assert_float(Balance.config.speed_up_boost_duration).is_greater(0.0)
	assert_int(Balance.config.transition_score).is_greater(0)
	assert_float(Balance.config.spawn_buffer_px).is_greater(0.0)
