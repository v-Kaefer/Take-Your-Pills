extends HBoxContainer
class_name BoostBarRow

const COLOR_STRIPE_EMPTY := Color(0.25, 0.25, 0.3, 0.5)

@export_node_path("TextureRect") var icon_path: NodePath
@export_node_path("HBoxContainer") var stripes_path: NodePath
@export var icon_texture_path: String = ""
@export var filled_color: Color = Color(0.25, 0.55, 1.0, 1.0)

var _icon: TextureRect = null
var _stripes: HBoxContainer = null
var _charge: int = 0


func _ready() -> void:
	_icon = get_node_or_null(icon_path) as TextureRect
	_stripes = get_node_or_null(stripes_path) as HBoxContainer

	if _icon != null and not icon_texture_path.is_empty():
		_icon.texture = load(icon_texture_path) as Texture2D

	reset_bar()


func apply_charge(charge: int) -> void:
	_charge = clampi(charge, 0, _get_stripe_count())
	_refresh()


func reset_bar() -> void:
	_charge = 0
	_refresh()


func _get_stripe_count() -> int:
	if _stripes == null:
		return 0

	return _stripes.get_child_count()


func _refresh() -> void:
	if _stripes == null:
		return

	var stripe_nodes := _stripes.get_children()
	for i in range(stripe_nodes.size()):
		var rect := stripe_nodes[i] as ColorRect
		if rect == null:
			continue

		if i < _charge:
			rect.color = filled_color
		else:
			rect.color = COLOR_STRIPE_EMPTY
