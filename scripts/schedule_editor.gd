class_name ScheduleEditor extends PanelContainer

signal remove

var pl: Prologot
var schedule: Schedule
@onready var _timing_grid: GridContainer = %Timing
@onready var _the_grid: GridContainer = %TheGrid
@onready var _rev_grid: GridContainer = %ReverseGrid
@onready var _time_panel: PopupPanel = %TimePanel
@onready var _time_editor: Control = %TimeEditor
@export var clock_icon: EditorIcon

var _edit_time_label: TimeLabel

func edit(schedule: Schedule):
	self.schedule = schedule
	_edit_time_label = null
	_time_panel.hide()
	%Name.text = schedule.name if schedule != null else ''
	Util.clear_children(_timing_grid)

	if schedule == null:
		%ForwardPath.path = []
		%ReversePath.path = []
		Util.clear_children(_the_grid)
		Util.clear_children(_rev_grid)
		return

	%ForwardPath.path = [schedule.path_names[0], schedule.path_names[-1]]
	%ReversePath.path = [schedule.path_names[-1], schedule.path_names[0]]

	_timing_grid.columns = schedule.path.size()
	for station in schedule.path:
		var label := Label.new()
		label.label_settings = preload('res://resources/station_name.tres')
		label.text = station.name
		_timing_grid.add_child(_wrap_cell(label))
	for idx in range(schedule.path.size()):
		var label := TimeDeltaLabel.new()
		label.editor = self
		if idx == 0:
			label.set_time(0)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.focus_mode = Control.FOCUS_NONE
		else:
			label.set_time(schedule.timings[idx - 1] if idx <= schedule.timings.size() else 0)
		_timing_grid.add_child(label)
	_refresh_grids()

func _refresh_grids():
	_refresh_grid(_the_grid, schedule.forward_plans, false)
	_refresh_grid(_rev_grid, schedule.reverse_plans, true)

func _refresh_grid(grid: GridContainer, plans: PackedInt32Array, reverse: bool):
	Util.clear_children(grid)
	var time_entries := maxi(3, plans.size() + 1)
	grid.columns = time_entries + 1
	#var tl := TextureRect.new()
	#tl.texture = clock_icon
	#tl.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	#grid.add_child(_wrap_cell(tl))
	#for idx in range(time_entries):
	#	grid.add_child(_wrap_cell(Control.new()))
	for _stat in range(schedule.path.size()):
		var stat := schedule.path.size() - _stat - 1 if reverse else _stat
		var station := schedule.path[stat]
		var label := Label.new()
		label.label_settings = preload('res://resources/station_name.tres')
		label.text = station.name
		grid.add_child(_wrap_cell(label))
		for idx in range(time_entries):
			grid.add_child(_wrap_cell(Control.new()))

static func _wrap_cell(cell: Control) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &'GridCell'
	panel.add_child(cell)
	return panel

func _on_remove():
	remove.emit()

func _compute_timings():
	if schedule == null:
		return
	var timings = pl.call_function('compute_route_timings', [schedule.name])
	print(timings)
	schedule.timings = timings
	var offs := schedule.path.size()
	for idx in range(1, schedule.path.size()):
		_timing_grid.get_child(offs + idx).set_time(schedule.timings[idx - 1])
	_refresh_grids()

func popup_time_panel(label: TimeLabel):
	_edit_time_label = label
	_time_editor.set_time(label.time)
	_time_panel.popup(Rect2(label.global_position + Vector2(0, label.size.y), Vector2()))

func _time_panel_closed():
	if _edit_time_label != null:
		_edit_time_label.set_time(_time_editor.time)
		_edit_time_label = null

class TimeLabel extends PanelContainer:
	var time: int
	var editor: ScheduleEditor
	var _hbox := HBoxContainer.new()
	var _icon := TextureRect.new()
	var _label := Label.new()

	func _init():
		focus_mode = Control.FOCUS_ALL
		theme_type_variation = &'GridCell'
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label.label_settings = preload('res://resources/time_label.tres')
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon := EditorIcon.new()
		icon.icon = &'Time'
		_icon.texture = icon
		_hbox.add_child(_icon)
		_hbox.add_child(_label)
		add_child(_hbox)

	func set_time(mins: int):
		time = mins
		_label.text = _format()

	func _format() -> String:
		return Util.format_time(time)

	func _notification(what):
		if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_FOCUS_ENTER:
			theme_type_variation = &'GridCellHighlight'
		elif what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_FOCUS_EXIT:
			if not has_focus():
				theme_type_variation = &'GridCell'

	func _gui_input(event: InputEvent):
		var mb := event as InputEventMouseButton
		if event.is_action_pressed("ui_accept") or (mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed):
			editor.popup_time_panel(self)

class TimeDeltaLabel extends TimeLabel:
	func _format() -> String:
		return '+ ' + Util.format_time(time)
