@tool class_name RouteDisplay extends HFlowContainer

@export var path: PackedStringArray:
	get: return path.duplicate()
	set(arr):
		path = arr
		queue_layout()

@export var track_schedule: Schedule:
	get: return track_schedule
	set(sched):
		if track_schedule != null:
			track_schedule.path_changed.disconnect(_sched_changed)
		track_schedule = sched
		if track_schedule != null:
			track_schedule.path_changed.connect(_sched_changed)
			_sched_changed()

func queue_layout():
	if not _layout_queued and is_node_ready():
		_layout_queued = true
		_relayout.call_deferred()

var _layout_queued := false

func _ready():
	queue_layout()

func _relayout():
	_layout_queued = false
	Util.clear_children(self)

	if path.is_empty():
		var l := Label.new()
		l.text = 'empty path'
		l.add_theme_color_override(&'font_color', Color.SLATE_GRAY)
		add_child(l)
		return

	var first := true
	for elem in path:
		if first:
			first = false
		else:
			add_child(Sep.new())
		var l := Label.new()
		l.text = elem
		l.label_settings = preload('res://resources/station_name.tres')
		add_child(l)

func _sched_changed():
	if track_schedule != null:
		path = track_schedule.path_names
	else:
		path = PackedStringArray()

class Sep extends Label:
	func _init():
		text = '>>'
		add_theme_color_override(&'font_color', Color.DARK_SALMON)
