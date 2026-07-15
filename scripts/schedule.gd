class_name Schedule extends Resource

@export var name: String
@export var path_names: PackedStringArray
var fully_loaded: bool = false
var path: Array[Station]
var timings: PackedInt32Array
var forward_plans: PackedInt32Array
var reverse_plans: PackedInt32Array

signal path_changed

func add_station(station: Station):
	path.push_back(station)
	path_names.push_back(station.name)
	path_changed.emit()

func clear():
	path.clear()
	path_names.clear()
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

func load_route(pl: Prologot, map: MapView):
	var res = pl.query_one('schedule_route', [name, '_'])
	path_names = res['args'][1]
	path.resize(path_names.size())
	for idx in range(path_names.size()):
		path[idx] = map.get_node(path_names[idx]) as Station

func load(pl: Prologot, map: MapView):
	load_route(pl, map)
	var res = pl.query_one('schedule_timings', [name, '_'])
	if res != null:
		timings = PackedInt32Array(res['args'][1])
	else:
		timings.clear()
	res = pl.query_all('schedule_run', [name, 'From', 'To', 'Time'])
	forward_plans.clear()
	reverse_plans.clear()
	for run in res:
		var from: String = run['args'][1]
		var to: String = run['args'][2]
		var time: int = run['args'][3]
		if from == path_names[0] and to == path_names[-1]:
			forward_plans.push_back(time)
		elif from == path_names[-1] and to == path_names[0]:
			reverse_plans.push_back(time)
		else:
			push_warning('Invalid run for %s: %s to %s' % [name, from, to])
	forward_plans.sort()
	reverse_plans.sort()
	fully_loaded = true

func save_to_db(writer):
	writer.term('schedule', name)
	writer.term('schedule_route', name, path_names)
	writer.term('schedule_timings', name, timings)
	if path.size() >= 2:
		var start := path_names[0]
		var end := path_names[-1]
		for run in forward_plans:
			writer.term('schedule_run', name, start, end, run)
		for run in reverse_plans:
			writer.term('schedule_run', name, end, start, run)
	fully_loaded = true

func remove_from_db(pl: Prologot):
	pl.retract_all('schedule_route(%s, _)' % [name])
	pl.retract_all('schedule_timings(%s, _)' % [name])
	pl.retract_all('schedule_run(%s, _, _, _)' % [name])
	pl.retract_fact('schedule(%s)' % [name])
