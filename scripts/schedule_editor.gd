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

enum Section {
	Timings,
	Forward,
	Reverse,
}

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
		label.section = Section.Timings
		if idx == 0:
			label.set_time(0)
			label.disable()
		else:
			label.plan_idx = idx - 1
			label.set_time(schedule.timings[idx - 1] if idx <= schedule.timings.size() else 0)
		_timing_grid.add_child(label)
	_refresh_grids()

func _refresh_grids():
	_refresh_grid(Section.Forward)
	_refresh_grid(Section.Reverse)

func _refresh_grid(which: Section):
	var grid: GridContainer
	var plans: PackedInt32Array
	var remove_button: Button
	var reverse: bool
	match which:
		Section.Forward:
			grid = _the_grid
			plans = schedule.forward_plans
			remove_button = %RemoveLastForward
			reverse = false
		Section.Reverse:
			grid = _rev_grid
			plans = schedule.reverse_plans
			remove_button = %RemoveLastReverse
			reverse = true

	remove_button.disabled = plans.is_empty()

	Util.clear_children(grid)
	var time_entries := plans.size() + 1
	grid.columns = time_entries + 1
	#var tl := TextureRect.new()
	#tl.texture = clock_icon
	#tl.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	#grid.add_child(_wrap_cell(tl))
	#for idx in range(time_entries):
	#	grid.add_child(_wrap_cell(Control.new()))
	var offset := 0
	for _stat in range(schedule.path.size()):
		var stat := schedule.path.size() - _stat - 1 if reverse else _stat
		var del := stat if reverse else _stat - 1
		if _stat > 0 and del < schedule.timings.size():
			offset += schedule.timings[del]
		var station := schedule.path[stat]
		var label := Label.new()
		label.label_settings = preload('res://resources/station_name.tres')
		label.text = station.name
		grid.add_child(_wrap_cell(label))
		for idx in range(time_entries):
			if idx < plans.size():
				var time := TimeLabel.new()
				time.set_time(offset + plans[idx])
				if _stat == 0:
					time.editor = self
					time.section = which
					time.plan_idx = idx
				else:
					time.disable()
				grid.add_child(time)
			else:
				if _stat == 0:
					var slot := AddTimeLabel.new()
					slot.editor = self
					slot.section = which
					grid.add_child(slot)
				else:
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
		if _edit_time_label is AddTimeLabel:
			match _edit_time_label.section:
				Section.Forward:
					schedule.forward_plans.push_back(_edit_time_label.time)
				Section.Reverse:
					schedule.reverse_plans.push_back(_edit_time_label.time)
		elif _edit_time_label.plan_idx != -1:
			match _edit_time_label.section:
				Section.Timings:
					schedule.timings[_edit_time_label.plan_idx] = _edit_time_label.time
				Section.Forward:
					schedule.forward_plans[_edit_time_label.plan_idx] = _edit_time_label.time
				Section.Reverse:
					schedule.reverse_plans[_edit_time_label.plan_idx] = _edit_time_label.time
		if _edit_time_label.section == Section.Timings:
			_refresh_grids()
		else:
			_refresh_grid(_edit_time_label.section)
		_edit_time_label = null

class TimeLabel extends ClickablePanel:
	var time: int
	var editor: ScheduleEditor
	var section: ScheduleEditor.Section
	var plan_idx: int = -1

	var _hbox := HBoxContainer.new()
	var _icon := TextureRect.new()
	var _label := Label.new()

	func _init():
		super._init()
		pressed.connect(_pressed)
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

	func _pressed():
		editor.popup_time_panel(self)

class AddTimeLabel extends TimeLabel:
	func _init():
		theme_type = &'GridCellNew'
		super._init()
		set_time(0)
	func _format() -> String:
		return 'Add plan'

class TimeDeltaLabel extends TimeLabel:
	func _format() -> String:
		return '+ ' + Util.format_time(time)

func _remove_last_plan(which: Section):
	var plans := schedule.reverse_plans if which == Section.Reverse else schedule.forward_plans
	if not plans.is_empty():
		plans.remove_at(plans.size() - 1)
		_refresh_grid(which)
