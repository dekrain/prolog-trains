class_name ScheduleEditor extends PanelContainer

signal remove

var schedule: Schedule
@onready var _the_grid: GridContainer = %TheGrid
@export var clock_icon: EditorIcon

func edit(schedule: Schedule):
	self.schedule = schedule
	%Name.text = schedule.name
	Util.clear_children(_the_grid)
	var time_entries := 3
	_the_grid.columns = time_entries + 1
	var tl := TextureRect.new()
	tl.texture = clock_icon
	tl.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_the_grid.add_child(tl)
	for idx in range(time_entries):
		_the_grid.add_child(Control.new())
	for station in schedule.path:
		var label := Label.new()
		label.label_settings = preload('res://resources/station_name.tres')
		label.text = station.name
		_the_grid.add_child(label)
		for idx in range(time_entries):
			_the_grid.add_child(Control.new())

func _on_remove():
	remove.emit()
