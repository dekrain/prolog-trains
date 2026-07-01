@tool extends Control

@export var view: MapView

const GRIDLINE_MAJOR := Color.SILVER
const GRIDLINE_MAJOR_W := 3.0
const GRIDLINE_MINOR := Color.GRAY
const GRIDLINE_MINOR_W := 1.0

func _draw():
	# Fill the backgound color
	draw_rect(Rect2(Vector2(), size), Color.LIGHT_GRAY)
	# Draw the grid
	var x_org := draw_gridlines(VERTICAL, view.position.x, size.x, view.scale.x, size.y)
	var y_org := draw_gridlines(HORIZONTAL, view.position.y, size.y, view.scale.y, size.x)
	if x_org and y_org:
		draw_circle(view.position, 4.0, Color.BLACK)

func draw_gridlines(dir: Orientation, center: float, size: float, scale: float, rule_size: float) -> bool:
	#prints(dir, center, size, scale)
	# Major gridlines: 1x, 2x, 4x, 8x, etc.
	# Minor gridlines: major/4
	# Major gridline spacing: 50px to 100px
	var spacing_raw := 50.0 / scale
	var shift := 0
	while spacing_raw < 1.0:
		spacing_raw *= 2.0
		shift += 1
	var spacing_u := nearest_po2(ceili(spacing_raw)) * 2.0**-shift
	var spacing_um := spacing_u / 4.0
	var low := -center / scale
	var high := low + size / scale
	var pos := ceilf(low / spacing_um) * spacing_um
	var part := ceili(low / spacing_um)
	var in_editor := Engine.is_editor_hint()
	while pos < high:
		var screen_pos = pos * scale + center
		var is_major := part % 4 == 0
		if not in_editor or is_major:
			var color := GRIDLINE_MAJOR if is_major else GRIDLINE_MINOR
			var width := GRIDLINE_MAJOR_W if is_major else GRIDLINE_MINOR_W
			if dir == HORIZONTAL:
				draw_line(Vector2(0.0, screen_pos), Vector2(rule_size, screen_pos), color, width)
			else:
				draw_line(Vector2(screen_pos, 0.0), Vector2(screen_pos, rule_size), color, width)
		pos += spacing_um
		part += 1
	return low <= 0.0 and 0.0 <= high
