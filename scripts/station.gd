class_name Station extends MapObject

const OUTLINE_HOVER := Color.ANTIQUE_WHITE
const OUTLINE_REMOVE := Color.CRIMSON
const OUTLINE_SELECTED := Color.AQUAMARINE

var polygon := Polygon2D.new()
var outline := Polygon2D.new()
var col := CollisionPolygon2D.new()

var _roads: Array[Road]

const SAVE_NAME := 1
const SAVE_POS := 2
const SAVE_COLOR := 4
const SAVE_SHAPE := 8
const SAVE_ALL := 15

func _ready():
	add_child(col)
	outline.hide()
	add_child(outline)
	add_child(polygon)

func apply(vbuf: PackedVector2Array, color: Color):
	col.polygon = vbuf
	polygon.polygon = vbuf
	polygon.color = color
	for idx in range(vbuf.size()):
		vbuf[idx] *= 1.2
	outline.polygon = vbuf

func generate():
	var verts := randi_range(3, 6)
	var vbuf := PackedVector2Array()
	var abuf := PackedFloat32Array()
	vbuf.resize(verts)
	abuf.resize(verts + 1)
	for idx in range(verts + 1):
		abuf[idx] = randf()
	abuf.sort()
	var max_ang := abuf[verts]
	for idx in range(verts):
		vbuf[idx] = Vector2.from_angle(abuf[idx] * TAU / max_ang) * randf_range(9.3, 11.6)
	apply(vbuf, Color.from_ok_hsl(randf(), randf_range(0.2, 0.7), 0.6))

func attach_road(road: Road):
	_roads.push_back(road)

func _apply_state():
	if _state & STATE_SELECTED:
		outline.color = OUTLINE_SELECTED
		outline.show()
	elif _state & STATE_HOVERED_REMOVE:
		outline.color = OUTLINE_REMOVE
		outline.show()
	elif _state & STATE_HOVERED:
		outline.color = OUTLINE_HOVER
		outline.show()
	else:
		outline.hide()

func save_to_db_all(writer):
	save_to_db(writer, SAVE_ALL)

func save_to_db(writer, flags: int):
	if flags & SAVE_NAME:
		writer.term('station', name)
	if flags & SAVE_POS:
		writer.term('station_xy', name, position.x, position.y)
	if flags & SAVE_COLOR:
		writer.term('station_color', name, polygon.color.r8, polygon.color.g8, polygon.color.b8)
	if flags & SAVE_SHAPE:
		writer.term('station_shape', name, polygon.polygon)

func load_from_db(pl: Prologot):
	assert(pl.query('station', [name]))
	var res: Dictionary = pl.query_one('station_xy', [name, '_', '_'])
	position = Vector2(res['args'][1], res['args'][2])
	res = pl.query_one('station_color', [name, '_', '_', '_'])
	var color := Color8(res['args'][1], res['args'][2], res['args'][3])
	res = pl.query_one('station_shape', [name, '_'])
	var shape := (res['args'][1] as PackedFloat32Array).to_byte_array().to_vector2_array()
	apply(shape, color)

func remove_from_db(pl: Prologot) -> bool:
	if not _roads.is_empty():
		return false
	pl.retract_all('station_xy(%s, _, _)' % [name])
	pl.retract_all('station_color(%s, _, _, _)' % [name])
	pl.retract_all('station_shape(%s, _)' % [name])
	pl.retract_fact('station(%s)' % [name])
	return true
