class_name Road extends MapObject

const SB_ROAD := preload('res://resources/road.stylebox')
const SB_OUTLINE := preload('res://resources/road_outline.tres')

const ROAD_WIDTH := 2.0
const MARGIN := 3.0

var from: Station
var to: Station
var quality: float = 1.0:
	get: return quality
	set(q):
		quality = clampf(q, 0.0, 1.0)
		_update_color()
		changed.emit()

var _panel := Panel.new()
var _outline := Panel.new()
var _col := CollisionShape2D.new()
var _rect := RectangleShape2D.new()

func _ready():
	_col.shape = _rect
	add_child(_col)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(&'panel', SB_ROAD)
	_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline.add_theme_stylebox_override(&'panel', SB_OUTLINE)
	_outline.hide()
	add_child(_outline)
	add_child(_panel)

func attach(from: Station, to: Station):
	self.from = from
	self.to = to
	from.attach_road(self)
	to.attach_road(self)
	rotation = from.position.angle_to_point(to.position)
	var length := from.position.distance_to(to.position)
	position = (from.position + to.position) * 0.5
	_rect.size = Vector2(length, ROAD_WIDTH)
	_panel.size = Vector2(length, ROAD_WIDTH)
	_panel.position = -_panel.size * 0.5
	_outline.size = Vector2(length + MARGIN, ROAD_WIDTH + MARGIN)
	_outline.position = -_outline.size * 0.5

func _update_color():
	_panel.self_modulate = Color(quality, quality, quality)

func _apply_state():
	if _state & STATE_SELECTED:
		_outline.self_modulate = OUTLINE_SELECTED
		_outline.show()
	elif _state & STATE_HOVERED_REMOVE:
		_outline.self_modulate = OUTLINE_REMOVE
		_outline.show()
	elif _state & STATE_HOVERED:
		_outline.self_modulate = OUTLINE_HOVER
		_outline.show()
	else:
		_outline.hide()

func save_to_db_all(writer):
	save_to_db(writer)

func save_to_db(writer):
	writer.term('road', from.name, to.name, quality)

func load_from_db(pl: Prologot):
	var res: Dictionary = pl.query_one('road', [from.name, to.name, '_'])
	quality = res['args'][2]

func remove_from_db(pl: Prologot, force: bool = false) -> bool:
	if not force and pl.query('road_part_of_schedule', [from.name, to.name]):
		return false
	from._roads.erase(self)
	to._roads.erase(self)
	pl.retract_all('road(%s, %s, _)' % [from.name, to.name])
	return true
