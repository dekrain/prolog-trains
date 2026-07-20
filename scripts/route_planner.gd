class_name RoutePlanner extends PanelContainer

const TimeEditor = preload('res://scripts/time_editor.gd')

signal transition(is_full_screen: bool)
signal popup_opened
signal popup_closed

var pl: Prologot
var map: MapView
var schedule := Schedule.new()

@onready var _route: RouteDisplay = %Route
@onready var _time_from: TimeLabel = %TimeFrom
@onready var _time_to: TimeLabel = %TimeTo
@onready var _max_results: SpinBox = %MaxResults
@onready var _results: VBoxContainer = %Results
@onready var _time_panel: PopupPanel = %TimePanel
@onready var _time_editor: TimeEditor = %TimeEditor

var _expanded := false
var _edit_time_label: TimeLabel
var _spinner := LoadingSpinner.new()
var _fold_group := FoldableGroup.new()
var _worker_engine: PrologotEngine
var _process_task: int = -1

func _ready():
	Util.set_parent(_spinner, $Recycler)
	_route.track_schedule = schedule
	schedule.path_changed.connect(_path_changed)
	_fold_group.allow_folding_all = true

func _path_changed():
	%ShowResults.disabled = _route.path.size() < 2

func _popup_time_panel(label: TimeLabel):
	if not _expanded:
		popup_opened.emit()
	_edit_time_label = label
	_time_editor.set_time(label.time)
	_time_panel.popup(Rect2(label.global_position + Vector2(0, label.size.y), Vector2()))

func _time_panel_closed():
	if not _expanded:
		popup_closed.emit()
	if _edit_time_label != null:
		_edit_time_label.set_time(_time_editor.time)
		_edit_time_label = null

func _show_results():
	_expanded = true
	transition.emit(true)
	%ShowResults.hide()
	%ResultsBox.show()
	Util.set_parent(_spinner, _results)
	if _worker_engine == null:
		_worker_engine = PrologotEngine.new()
	if _process_task != -1:
		var task := _process_task
		_process_task = -1
		WorkerThreadPool.wait_for_task_completion(task)
	_process_task = WorkerThreadPool.add_task(_process_query_work, false, 'Route planner task')

func _process_query_work():
	var tfrom: int = _time_from.time
	var tto: int = _time_to.time
	var path: PackedStringArray = _route.path
	var max: int = _max_results.value
	_worker_engine.set_active_for_this_thread()
	# Error handling can race.
	# TODO: Move error state to PrologotEngine
	var result = Util.pl_call_function(pl, 'find_routes', [tfrom, tto, path as Array, max])
	PrologotEngine.deactivate()
	_populate_results.call_deferred(result)

func _populate_results(result: Array):
	if _process_task == -1:
		return
	Util.set_parent(_spinner, $Recycler)
	Util.clear_children(_results)
	for rt in result:
		var route := _parse_route(rt)
		var display := preload('res://scenes/travel_route_display.tscn').instantiate()
		display.foldable_group = _fold_group
		display.setup.call_deferred(route)
		_results.add_child(display)

func contract():
	if _process_task != -1:
		var task := _process_task
		_process_task = -1
		WorkerThreadPool.wait_for_task_completion(task)
	_expanded = false
	%ResultsBox.hide()
	%ShowResults.show()
	transition.emit(false)
	Util.set_parent(_spinner, $Recycler)
	Util.clear_children(_results)

class FoundRoute extends RefCounted:
	var path: Array[PathSegment]
	var num_trains: int
	var start_time: int
	var end_time: int
	var score: float

class PathSegment extends RefCounted:
	var dt: int
	var cost: float

class PathSegRide extends PathSegment:
	var schedule: Schedule
	var from: Station
	var to: Station
	static var theme_type := &'PathSegRide'
	static var icon := &'TrackContinuous'

class PathSegWait extends PathSegment:
	static var theme_type := &'PathSegWait'
	static var icon := &'Time'

func _parse_route(route: Dictionary) -> FoundRoute:
	assert(route['functor'] == 'route')
	var result := FoundRoute.new()
	var path: Array = route['args'][0]
	result.score = route['args'][1]
	# Path is returned in reversse
	var start = path.pop_back()
	assert(start['functor'] == 'start')
	result.start_time = start['args'][0]
	result.end_time = result.start_time
	result.num_trains = 1
	var schedule_cache: Dictionary[String, Schedule]
	while !path.is_empty():
		var seg = path.pop_back()
		match seg.functor:
			'ride':
				var rseg := PathSegRide.new()
				rseg.schedule = _get_schedule(seg.args[0], schedule_cache)
				rseg.from = _get_station(seg.args[1])
				rseg.to = _get_station(seg.args[2])
				rseg.dt = seg.args[3]
				rseg.cost = seg.args[4]
				result.path.push_back(rseg)
				result.end_time = Util.time_add(result.end_time, rseg.dt)
			'wait':
				var rseg := PathSegWait.new()
				rseg.dt = seg.args[0]
				rseg.cost = seg.args[1]
				result.path.push_back(rseg)
				result.num_trains += 1
				result.end_time = Util.time_add(result.end_time, rseg.dt)
			_:
				push_error('Unknown path segment: ', seg.functor)
	return result

func _get_schedule(name: String, cache: Dictionary[String, Schedule]) -> Schedule:
	if name in cache:
		return cache[name]
	var sched := Schedule.new()
	sched.name = name
	cache[name] = sched
	return sched

func _get_station(name: String) -> Station:
	var obj: MapObject = map.get_node(name)
	var station := obj as Station
	assert(station != null)
	return station
