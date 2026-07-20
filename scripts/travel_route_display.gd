extends FoldableContainer

@onready var _start_time: TimeLabel = %StartTime
@onready var _end_time: TimeLabel = %EndTime
@onready var _n_trains: Label = %NumTrains
@onready var _score: Label = %Score
@onready var _segments: VBoxContainer = %Segments

func _ready():
	var header: Control = get_child(0)
	remove_child(header)
	header.show()
	add_title_bar_control(header)
	_start_time.disable()
	_end_time.disable()

func setup(route: RoutePlanner.FoundRoute):
	_start_time.set_time(route.start_time)
	_end_time.set_time(route.end_time)
	_n_trains.text = str(route.num_trains)
	_score.text = String.num(route.score, 2)
	for seg in route.path:
		var seg_disp := SegmentDisplay.new()
		seg_disp.theme_type = seg.theme_type
		seg_disp.icon_name = seg.icon
		seg_disp.dt = seg.dt
		seg_disp.cost = seg.cost
		var ride := seg as RoutePlanner.PathSegRide
		if ride != null:
			seg_disp.setup_ride(ride)
		_segments.add_child(seg_disp)

class SegmentDisplay extends ClickablePanel:
	var dt: int
	var cost: float
	var icon_name: StringName

	var _hbox := HBoxContainer.new()
	var _icon := TextureRect.new()
	var _l_dt := Label.new()
	var _d_dt := TimeLabel.new()
	var _cost_dt := Label.new()

	func _init():
		super._init()
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hbox.add_child(_icon)
		_l_dt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_l_dt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_l_dt.text = 'Delta:'
		_hbox.add_child(_l_dt)
		_d_dt.disable()
		_hbox.add_child(_d_dt)
		_cost_dt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cost_dt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_hbox.add_child(_cost_dt)
		add_child(_hbox)

	func setup_ride(ride: RoutePlanner.PathSegRide):
		#var pad := Control.new()
		#pad.custom_minimum_size.x = 50.0
		#_hbox.add_child(pad)
		var rd := RouteDisplay.new()
		rd.path = [ride.from.name, ride.to.name]
		rd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rd.alignment = FlowContainer.ALIGNMENT_CENTER
		_hbox.add_child(rd)
		var sched := Label.new()
		sched.text = ride.schedule.name
		sched.label_settings = preload('res://resources/schedule_name.tres')
		sched.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sched.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sched.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_hbox.add_child(sched)

	func _ready():
		super._ready()
		var icon := EditorIcon.new()
		icon.icon = icon_name
		_icon.texture = icon
		_d_dt.set_time(dt)
		_cost_dt.text = 'Cost: ' + String.num(cost, 2)
