extends Node

var pl := Prologot.new()
var _pl_writer
@onready var view: MapView = $View
@onready var ui: Control = $MapUI
@onready var _tools: ItemList = ui.get_node(^'%Tools')
@onready var _overlay: ScreenOverlay = $Overlay
@onready var _sched_ed: ScheduleEditor = $ScheduleEditor

enum Tool {
	PAN,
	SELECT,
	PLACE_STATION,
	PLACE_ROAD,
	SET_SCHEDULE,
	PLAN_ROUTE,
	REMOVE,
}

var _hover_object: MapObject = null
var _selected_object: MapObject = null
var _building_path: Schedule = null
var _dragging := false
var _current_tool := Tool.PAN

func _ready():
	pl.initialize()
	_pl_writer = preload('res://scripts/prolog_writer.gd').new(pl)
	_sched_ed.pl = pl
	view.local_transform_changed.connect(_view_changed)
	get_viewport().size_changed.connect(_view_changed)
	_tools.select(0)
	_tools.item_selected.connect(_tool_changed)
	center_around(Vector2())
	ui.get_node(^'%Save').pressed.connect(save_map)
	ui.get_node(^'%Load').pressed.connect(load_map)
	$RoadDetails/%Quality.value_changed.connect(func(v: float):
		var road := _selected_object as Road
		if road != null:
			road.quality = v
	)
	#pl.consult_file('res://db.pl')
	pl.consult_file('res://rules.pl')
	load_map()

func center_around(point: Vector2):
	view.position = point * view.scale + get_viewport().size * 0.5

const ZOOM_SENS := 1.04

func zoom_view_by(scale: float, pivot: Vector2):
	var rel := view.position - pivot
	view.apply_scale(Vector2(scale, scale))
	view.position = pivot + rel * scale

func save_map():
	var writer := preload('res://scripts/facts_writer.gd').new()
	writer.open('res://db.pl')
	writer.comment('station(name)')
	writer.directive('dynamic station/1')
	for child in view.get_children():
		var station := child as Station
		if station != null:
			station.save_to_db(writer, Station.SAVE_NAME)
	writer.blank_line()
	writer.comment('station_xy(name, X, Y)')
	writer.directive('dynamic station_xy/3')
	writer.directive('discontiguous station_xy/3')
	writer.comment('station_color(name, R, G, B)')
	writer.directive('dynamic station_color/4')
	writer.directive('discontiguous station_color/4')
	writer.comment('station_shape(name, Vertices)')
	writer.directive('dynamic station_shape/2')
	writer.directive('discontiguous station_shape/2')
	for child in view.get_children():
		var station := child as Station
		if station != null:
			station.save_to_db(writer, Station.SAVE_POS | Station.SAVE_COLOR | Station.SAVE_SHAPE)
	writer.blank_line()
	writer.comment('road(from_station, to_station, Q)')
	writer.directive('dynamic road/3')
	for child in view.get_children():
		var road := child as Road
		if road != null:
			road.save_to_db(writer)
	writer.blank_line()
	writer.comment('schedule(name)')
	writer.directive('dynamic schedule/1')
	var qres := pl.query_all('schedule', ['N'])
	for fact in qres:
		writer.term('schedule', fact['N'])
	writer.blank_line()
	writer.comment('schedule_route(name, Stations)')
	writer.directive('dynamic schedule_route/2')
	qres = pl.query_all('schedule_route', ['N', 'P'])
	for fact in qres:
		writer.term('schedule_route', fact['N'], fact['P'])
	writer.blank_line()
	writer.comment('schedule_timings(name, RoadDeltas)')
	writer.directive('dynamic schedule_timings/2')
	qres = pl.query_all('schedule_timings', ['N', 'R'])
	for fact in qres:
		writer.term('schedule_timings', fact['N'], fact['R'])
	writer.blank_line()
	writer.comment('schedule_run(name, From, To, StartTime)')
	writer.directive('dynamic schedule_run/4')
	qres = pl.query_all('schedule_run', ['N', 'S', 'E', 'T'])
	for fact in qres:
		writer.term('schedule_run', fact['N'], fact['S'], fact['E'], fact['T'])

func load_map():
	assert(pl.query('reload_db'))
	select_object(null)
	Util.clear_children(view)
	var stations := pl.query_all('station', ['Name'])
	for st in stations:
		var obj := Station.new()
		obj.name = st['Name']
		obj.load_from_db(pl)
		_add_object(obj)
	var roads := pl.query_all('road', ['From', 'To', 'Q'])
	for road in roads:
		var from: Station = view.get_node(road['From'])
		var to: Station = view.get_node(road['To'])
		var obj := Road.new()
		obj.name = 'r_%s_%s' % [from.name, to.name]
		obj.attach(from, to)
		obj.load_from_db(pl)
		_add_object(obj)
	if $ScheduleList.visible:
		_refresh_schedules()

func _unhandled_input(event):
	if _overlay.visible:
		return
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			match _current_tool:
				Tool.PAN:
					_dragging = mb.pressed
				Tool.SELECT:
					if mb.pressed:
						select_object(_hover_object)
				Tool.REMOVE:
					if mb.pressed and _hover_object != null:
						remove_object(_hover_object)
				Tool.PLACE_STATION:
					if mb.pressed:
						_place_station_at(mb.position)
				Tool.PLACE_ROAD:
					if mb.pressed:
						var st := _hover_object as Station
						if st != null:
							if _selected_object == null:
								select_object(st)
							else:
								_place_road(_selected_object, st)
						else:
							select_object(null)
				Tool.SET_SCHEDULE:
					if mb.pressed:
						var station := _hover_object as Station
						if station != null:
							if not station._state & MapObject.STATE_SELECTED:
								if _building_path == null:
									_building_path = Schedule.new()
									$ScheduleList/%Current.show()
									$ScheduleList/%CurrentRoute.track_schedule = _building_path
								if _building_path.path.is_empty() or _has_road(_building_path.path.back(), station):
									_building_path.add_station(station)
									station.set_state(MapObject.STATE_SELECTED, true)
						elif _building_path != null:
							if _building_path.path.size() >= 2:
								_commit_path()
							else:
								_reset_path()
				Tool.PLAN_ROUTE: pass
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_view_by(ZOOM_SENS, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_view_by(1.0 / ZOOM_SENS, mb.position)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			# Pan view regardless of view
			_dragging = mb.pressed
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		if _dragging:
			view.position += mm.relative
			get_viewport().set_input_as_handled()
		return

func _view_changed():
	var tl := view.to_local(Vector2())
	var br := view.to_local(Vector2(get_viewport().size))
	ui.get_node(^'%Bounds').text = 'L=%.2f T=%.2f R=%.2f B=%.2f' % [tl.x, tl.y, br.x, br.y]
	#ui.get_node(^'%Bounds').text = 'L=%s T=%s R=%s B=%s' % [tl.x, tl.y, br.x, br.y].map(func(n): return String.num(n, 2))

func _tool_changed(idx: int):
	_dragging = false
	if _building_path != null:
		_reset_path()
	if _hover_object != null:
		_hover_object.set_state(MapObject.ALL_STATES, false)
		_hover_object = null
	if _selected_object != null:
		select_object(null)
	_current_tool = idx as Tool
	if _current_tool == Tool.SET_SCHEDULE:
		$ScheduleList.show()
		_refresh_schedules()
	else:
		$ScheduleList.hide()

func _place_station_at(pos: Vector2):
	pos = view.to_local(pos)
	var station := Station.new()
	station.generate()
	station.position = pos
	_add_object(station)
	station.gen_name()
	station.save_to_db_all(_pl_writer)

func _place_road(from: Station, to: Station):
	select_object(null)
	if from == to or _has_road(from, to):
		return
	if to.name < from.name:
		var _tmp := from
		from = to
		to = _tmp
	var road_name := 'r_%s_%s' % [from.name, to.name]
	if view.has_node(road_name):
		return
	var road := Road.new()
	road.attach(from, to)
	_add_object(road)
	road.name = road_name
	road.save_to_db(_pl_writer)

func _add_object(obj: MapObject):
	obj.mouse_entered.connect(_obj_mouse_enter.bind(obj))
	obj.mouse_exited.connect(_obj_mouse_exit.bind(obj))
	obj.changed.connect(_obj_changed.bind(obj))
	view.add_child(obj)

func select_object(obj: MapObject):
	if _selected_object != null:
		_selected_object.set_state(MapObject.STATE_SELECTED, false)
		$StationDetails.hide()
		Util.clear_children($StationDetails/%Schedule)
		$RoadDetails.hide()
	_selected_object = obj
	if obj != null:
		obj.set_state(MapObject.STATE_SELECTED, true)
		if obj is Station:
			$StationDetails/%Name.text = obj.name
			$StationDetails/%XY.text = 'X: %.3f Y: %.3f' % [obj.position.x, obj.position.y]
			$StationDetails.show()
			_refresh_stops(obj)
		elif obj is Road:
			var road := obj as Road
			$RoadDetails/%From.text = road.from.name
			$RoadDetails/%To.text = road.to.name
			$RoadDetails/%Quality.set_value_no_signal(road.quality)
			$RoadDetails.show()

func remove_object(obj: MapObject):
	if _hover_object == obj:
		_hover_object = null
	if _selected_object == obj:
		_selected_object = null
	if obj.remove_from_db(pl):
		obj.queue_free()
	else:
		obj.set_state(MapObject.ALL_STATES, false)

func edit_schedule(schedule: Schedule):
	if not schedule.fully_loaded:
		schedule.load(pl, view)
	_overlay.show()
	_sched_ed.show()
	_sched_ed.edit(schedule)

func _obj_mouse_enter(obj: MapObject):
	if _current_tool in [Tool.SELECT, Tool.REMOVE, Tool.PLACE_ROAD, Tool.SET_SCHEDULE]:
		if (_current_tool == Tool.PLACE_ROAD or _current_tool == Tool.SET_SCHEDULE) and obj is not Station:
			return
		if _hover_object != null:
			_hover_object.set_state(MapObject.STATE_HOVERED_ALL, false)
		_hover_object = obj
		var state := MapObject.STATE_HOVERED_REMOVE if _current_tool == Tool.REMOVE else MapObject.STATE_HOVERED
		obj.set_state(state, true)

func _obj_mouse_exit(obj: MapObject):
	if _hover_object == obj:
		obj.set_state(MapObject.STATE_HOVERED_ALL, false)
		_hover_object = null

func _obj_changed(obj: MapObject):
	obj.remove_from_db(pl)
	obj.save_to_db_all(_pl_writer)

func _reset_path():
	for station in _building_path.path:
		station.set_state(MapObject.STATE_SELECTED, false)
	$ScheduleList/%Current.hide()
	$ScheduleList/%CurrentRoute.track_schedule = null
	_building_path = null

func _commit_path():
	_building_path.gen_name(pl)
	_building_path.save_to_db(_pl_writer)
	if $ScheduleList.visible:
		_refresh_schedules()
	edit_schedule(_building_path)
	_reset_path()

func _has_road(from: Station, to: Station):
	return pl.query('road_between', [from.name, to.name])

func _refresh_schedules():
	Util.clear_children($ScheduleList/%List)
	var schedules := pl.query_all('schedule', ['Name'])
	for res in schedules:
		var sched := Schedule.new()
		sched.name = res['Name']
		var btn := ScheduleButton.new()
		btn.schedule = sched
		btn.pressed.connect(edit_schedule.bind(sched))
		$ScheduleList/%List.add_child(btn)

func _refresh_stops(station: Station):
	Util.clear_children($StationDetails/%Schedule)
	var stops := pl.query_all('station_stop', [station.name, 'Schedule', 'Time', 'Reverse'])
	for stop in stops:
		var schedule := Schedule.new()
		schedule.name = stop['args'][1]
		schedule.load_route(pl, view)
		var reverse: bool = stop['args'][3] != 0
		var time: int = stop['args'][2]
		var entry := preload('res://scenes/station_schedule_entry.tscn').instantiate()
		entry.setup.call_deferred(schedule, reverse, time)
		var panel := ClickablePanel.new()
		panel.theme_type = &'InlineCell'
		panel.add_child(entry)
		panel.pressed.connect(edit_schedule.bind(schedule))
		$StationDetails/%Schedule.add_child(panel)

func close_overlay():
	_overlay.hide()
	_sched_ed.hide()
	if _sched_ed.schedule != null:
		_sched_ed.schedule.remove_from_db(pl)
		_sched_ed.schedule.save_to_db(_pl_writer)
		var sel_station := _selected_object as Station
		if sel_station != null:
			_refresh_stops(sel_station)

func _remove_schedule():
	_sched_ed.schedule.remove_from_db(pl)
	_sched_ed.edit(null)
	close_overlay()
	if $ScheduleList.visible:
		_refresh_schedules()
	var sel_station := _selected_object as Station
	if sel_station != null:
		_refresh_stops(sel_station)
