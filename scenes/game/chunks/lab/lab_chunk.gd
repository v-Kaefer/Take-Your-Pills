extends Chunk
class_name LabChunk

const GRID_COLUMNS := 10
const GRID_ROWS := 6
const TILE_SIZE := Vector2i(256, 256)
const TILE_SCALE := Vector2(0.25, 0.25)
const TILEMAP_OFFSET := Vector2(0, -12)

const TILE_VARIANTS := [&"orange_blue", &"yellow_brown"]
const TILE_NAMES := [
	&"bottom_left_edge",
	&"bottom_right_edge",
	&"bottom_tile",
	&"color",
	&"inner_corner_bottom_left",
	&"inner_corner_bottom_right",
	&"inner_corner_top_left",
	&"inner_corner_top_right",
	&"left_edge_repeating",
	&"left_tile",
	&"outer_corner_bottom_left",
	&"outer_corner_bottom_right",
	&"outer_corner_top_left",
	&"outer_corner_top_right",
	&"platform_inner_repeating",
	&"platform_left_edge",
	&"platform_right_edge",
	&"platform_single",
	&"right_edge_repeating",
	&"right_tile",
	&"top_left_edge",
	&"top_right_edge",
	&"top_tile",
]

static var _shared_tileset: TileSet = null
static var _shared_source_ids: Dictionary = {}

@export var layout_id: StringName = &"lab_a"
@onready var tile_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	super._ready()
	_ensure_tileset()
	_prepare_tile_layer()
	_paint_layout()
	tile_layer.update_internals()


func _ensure_tileset() -> void:
	if _shared_tileset != null:
		return

	_shared_tileset = TileSet.new()
	_shared_tileset.tile_size = TILE_SIZE
	_shared_source_ids = {}

	for variant in TILE_VARIANTS:
		for tile_name in TILE_NAMES:
			var source_key := _source_key(variant, tile_name)
			var texture_path := "res://assets/sets/lab_tileset/pngs/%s/%s.png" % [variant, tile_name]
			var image := Image.load_from_file(texture_path)
			if image.is_empty():
				push_error("Failed to load lab tile texture: %s" % texture_path)
				continue

			var texture := ImageTexture.create_from_image(image)
			if texture == null:
				push_error("Failed to create texture from lab tile image: %s" % texture_path)
				continue

			var atlas_source := TileSetAtlasSource.new()
			atlas_source.texture = texture
			atlas_source.texture_region_size = TILE_SIZE
			atlas_source.use_texture_padding = false
			atlas_source.create_tile(Vector2i.ZERO)
			_shared_source_ids[source_key] = _shared_tileset.add_source(atlas_source)


func _prepare_tile_layer() -> void:
	tile_layer.tile_set = _shared_tileset
	tile_layer.scale = TILE_SCALE
	tile_layer.position = TILEMAP_OFFSET
	tile_layer.z_index = -1
	tile_layer.clear()


func _paint_layout() -> void:
	_paint_base_shell()

	match layout_id:
		&"lab_b":
			_paint_lab_b()
		&"lab_c":
			_paint_lab_c()
		_:
			_paint_lab_a()


func _paint_base_shell() -> void:
	_fill_rect(Vector2i.ZERO, Vector2i(GRID_COLUMNS, GRID_ROWS), &"yellow_brown", &"color")
	_paint_ceiling_band()
	_paint_floor_band()
	_paint_side_columns()
	_paint_center_spine()
	_paint_window(Vector2i(1, 1), Vector2i(3, 3), &"orange_blue")
	_paint_window(Vector2i(6, 1), Vector2i(3, 3), &"orange_blue")
	_paint_catwalk(4, 2, 7, &"orange_blue")


func _paint_lab_a() -> void:
	_paint_window(Vector2i(1, 1), Vector2i(4, 3), &"orange_blue")
	_paint_equipment_stack(6, 1, &"yellow_brown")
	_paint_equipment_stack(8, 2, &"orange_blue")
	_paint_catwalk(3, 1, 5, &"yellow_brown")


func _paint_lab_b() -> void:
	_paint_window(Vector2i(2, 1), Vector2i(3, 3), &"orange_blue")
	_paint_window(Vector2i(6, 2), Vector2i(2, 2), &"yellow_brown")
	_paint_equipment_stack(1, 2, &"yellow_brown")
	_paint_equipment_stack(8, 1, &"orange_blue")
	_paint_catwalk(3, 0, 2, &"yellow_brown")
	_paint_catwalk(4, 6, 8, &"orange_blue")


func _paint_lab_c() -> void:
	_paint_window(Vector2i(1, 2), Vector2i(2, 2), &"orange_blue")
	_paint_window(Vector2i(4, 1), Vector2i(4, 3), &"yellow_brown")
	_paint_equipment_stack(2, 1, &"yellow_brown")
	_paint_equipment_stack(7, 2, &"orange_blue")
	_paint_catwalk(3, 1, 3, &"orange_blue")
	_paint_catwalk(4, 6, 8, &"yellow_brown")


func _paint_ceiling_band() -> void:
	for x in range(GRID_COLUMNS):
		if x == 0:
			_set_variant_cell(Vector2i(x, 0), &"yellow_brown", &"outer_corner_top_left")
		elif x == GRID_COLUMNS - 1:
			_set_variant_cell(Vector2i(x, 0), &"yellow_brown", &"outer_corner_top_right")
		else:
			_set_variant_cell(Vector2i(x, 0), &"yellow_brown", &"top_tile")


func _paint_floor_band() -> void:
	for x in range(GRID_COLUMNS):
		if x == 0:
			_set_variant_cell(Vector2i(x, GRID_ROWS - 1), &"yellow_brown", &"platform_left_edge")
		elif x == GRID_COLUMNS - 1:
			_set_variant_cell(Vector2i(x, GRID_ROWS - 1), &"yellow_brown", &"platform_right_edge")
		else:
			_set_variant_cell(Vector2i(x, GRID_ROWS - 1), &"yellow_brown", &"platform_inner_repeating")


func _paint_side_columns() -> void:
	for y in range(1, GRID_ROWS - 1):
		_set_variant_cell(Vector2i(0, y), &"yellow_brown", &"left_edge_repeating")
		_set_variant_cell(Vector2i(GRID_COLUMNS - 1, y), &"yellow_brown", &"right_edge_repeating")


func _paint_center_spine() -> void:
	for y in range(1, GRID_ROWS - 1):
		_set_variant_cell(Vector2i(5, y), &"yellow_brown", &"color")

	_set_variant_cell(Vector2i(5, 1), &"yellow_brown", &"top_tile")
	_set_variant_cell(Vector2i(5, 4), &"yellow_brown", &"bottom_tile")


func _paint_window(origin: Vector2i, size: Vector2i, variant: StringName) -> void:
	if size.x < 2 or size.y < 2:
		return

	var end_x := origin.x + size.x - 1
	var end_y := origin.y + size.y - 1

	for y in range(origin.y, end_y + 1):
		for x in range(origin.x, end_x + 1):
			if x == origin.x and y == origin.y:
				_set_variant_cell(Vector2i(x, y), variant, &"outer_corner_top_left")
			elif x == end_x and y == origin.y:
				_set_variant_cell(Vector2i(x, y), variant, &"outer_corner_top_right")
			elif x == origin.x and y == end_y:
				_set_variant_cell(Vector2i(x, y), variant, &"outer_corner_bottom_left")
			elif x == end_x and y == end_y:
				_set_variant_cell(Vector2i(x, y), variant, &"outer_corner_bottom_right")
			elif y == origin.y:
				_set_variant_cell(Vector2i(x, y), variant, &"top_tile")
			elif y == end_y:
				_set_variant_cell(Vector2i(x, y), variant, &"bottom_tile")
			elif x == origin.x:
				_set_variant_cell(Vector2i(x, y), variant, &"left_edge_repeating")
			elif x == end_x:
				_set_variant_cell(Vector2i(x, y), variant, &"right_edge_repeating")
			else:
				_set_variant_cell(Vector2i(x, y), variant, &"color")


func _paint_catwalk(row: int, start_x: int, end_x: int, variant: StringName) -> void:
	if end_x < start_x:
		return

	if start_x == end_x:
		_set_variant_cell(Vector2i(start_x, row), variant, &"platform_single")
		return

	_set_variant_cell(Vector2i(start_x, row), variant, &"platform_left_edge")
	for x in range(start_x + 1, end_x):
		_set_variant_cell(Vector2i(x, row), variant, &"platform_inner_repeating")
	_set_variant_cell(Vector2i(end_x, row), variant, &"platform_right_edge")


func _paint_equipment_stack(column: int, start_row: int, variant: StringName) -> void:
	_set_variant_cell(Vector2i(column, start_row), variant, &"platform_single")
	if start_row + 1 < GRID_ROWS - 1:
		_set_variant_cell(Vector2i(column, start_row + 1), variant, &"color")
	if start_row + 2 < GRID_ROWS - 1:
		_set_variant_cell(Vector2i(column, start_row + 2), variant, &"platform_single")


func _fill_rect(origin: Vector2i, size: Vector2i, variant: StringName, tile_name: StringName) -> void:
	var end_x := origin.x + size.x
	var end_y := origin.y + size.y
	for y in range(origin.y, end_y):
		for x in range(origin.x, end_x):
			_set_variant_cell(Vector2i(x, y), variant, tile_name)


func _set_variant_cell(coords: Vector2i, variant: StringName, tile_name: StringName) -> void:
	var source_id := _get_source_id(variant, tile_name)
	if source_id < 0:
		push_error("Missing lab tile source: %s/%s" % [variant, tile_name])
		return

	tile_layer.set_cell(coords, source_id, Vector2i.ZERO)


func _get_source_id(variant: StringName, tile_name: StringName) -> int:
	var source_key := _source_key(variant, tile_name)
	return int(_shared_source_ids.get(source_key, -1))


func _source_key(variant: StringName, tile_name: StringName) -> String:
	return "%s/%s" % [variant, tile_name]
