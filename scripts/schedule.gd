class_name Schedule extends Resource

@export var name: String
@export var path_names: PackedStringArray
var fully_loaded: bool = false
var path: Array[Station]

signal path_changed

func add_station(station: Station):
	path.push_back(station)
	path_names.push_back(station.name)
	path_changed.emit()

func gen_name(pl: Prologot):
	while true:
		var nm := ''.join(range(6).map(func(i): return String.chr(randi_range(0x61, 0x7A))))
		if not pl.query('schedule', [nm]):
			name = nm
			break

func translate_path():
	path_names.resize(path.size())
	for idx in range(path.size()):
		path_names[idx] = path[idx].name

func load(pl: Prologot, map: MapView):
	var res = pl.query_one('schedule_route', [name, '_'])
	path_names = res['args'][1]
	path.resize(path_names.size())
	for idx in range(path_names.size()):
		path[idx] = map.get_node(path_names[idx]) as Station
	fully_loaded = true

func save_to_db(writer):
	writer.term('schedule', name)
	writer.term('schedule_route', name, path_names)
	fully_loaded = true
