@tool extends Control

enum Mode {
	Hour,
	Minute,
}

@export var background: Color
@export var mode: Mode
@export var value: int = 0

signal value_changed

const RING_WIDTH := 18.0
const TEXT_SIZE := 15
const NUMBER_R := 8.0

func _init():
	value_changed.connect(queue_redraw)

func set_value(value: int):
	self.value = value
	queue_redraw()

func _get_minimum_size() -> Vector2:
	return Vector2(200.0, 200.0)

func _draw():
	var center := size * 0.5
	var radius = minf(size.x, size.y) * 0.5
	draw_circle(center, radius, background)
	draw_circle(center, radius - RING_WIDTH * 0.5, background.lightened(0.2), false, RING_WIDTH)

	var font := get_theme_font(&'font')
	if font == null:
		#print('Using fallback font')
		font = get_theme_font(&'font', &'Label')
		if font == null:
			#print('No theme font set')
			font = ThemeDB.fallback_font
	var descent := font.get_descent(TEXT_SIZE)
	var circle_color := background.blend(Color(Color.AZURE, 0.3))
	var highlight_color := background.blend(Color(Color.AZURE, 0.6))
	if mode == Mode.Hour:
		for idx in range(12):
			var dir := Vector2.from_angle(idx / 12.0 * TAU - TAU/4.0)
			var num := String.num_uint64(idx + 12)
			var highlighted := value == idx + 12
			var str_size := font.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)
			var offset := 0.5 * str_size
			offset.y = -offset.y + descent
			#draw_rect(Rect2(center + dir * (radius - 9.0) - str_size * 0.5, str_size), Color.BROWN)
			#draw_rect(Rect2(center + dir * (radius - 9.0) - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color.CORNFLOWER_BLUE)
			draw_circle(center + dir * (radius - 9.0), NUMBER_R, highlight_color if highlighted else circle_color)
			draw_string(font, center + dir * (radius - 9.0) - offset, num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)
			num = String.num_uint64(idx)
			highlighted = value == idx
			str_size = font.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)
			offset = 0.5 * str_size
			offset.y = -offset.y + descent
			#draw_rect(Rect2(center + dir * (radius - 30.0) - str_size * 0.5, str_size), Color.BROWN)
			#draw_rect(Rect2(center + dir * (radius - 30.0) - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color.CORNFLOWER_BLUE)
			draw_circle(center + dir * (radius - 30.0), NUMBER_R, highlight_color if highlighted else circle_color)
			draw_string(font, center + dir * (radius - 30.0) - offset, num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)
	else:
		for idx in range(6):
			var dir := Vector2.from_angle(idx / 6.0 * TAU - TAU/4.0)
			var num := String.num_uint64(idx * 10)
			var highlighted := value / 10 == idx
			var str_size := font.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)
			var offset := 0.5 * str_size
			offset.y = -offset.y + descent
			draw_circle(center + dir * (radius - 30.0), NUMBER_R, highlight_color if highlighted else circle_color)
			draw_string(font, center + dir * (radius - 30.0) - offset, num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)
		for idx in range(10):
			var dir := Vector2.from_angle(idx / 10.0 * TAU - TAU/4.0)
			var num := String.num_uint64(idx)
			var highlighted := value % 10 == idx
			var str_size := font.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)
			var offset := 0.5 * str_size
			offset.y = -offset.y + descent
			draw_circle(center + dir * (radius - 9.0), NUMBER_R, highlight_color if highlighted else circle_color)
			draw_string(font, center + dir * (radius - 9.0) - offset, num, HORIZONTAL_ALIGNMENT_CENTER, -1, TEXT_SIZE)

func _gui_input(event: InputEvent):
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5
		var rel := mb.position - center
		var ang := fmod(rel.angle() + TAU * 5.0/4.0, TAU)
		if mode == Mode.Hour:
			var sec := roundi(ang * 12.0 / TAU)
			if sec == 12:
				sec = 0
			var dir := Vector2.from_angle(sec / 12.0 * TAU - TAU/4.0)
			var bc := center + dir * (radius - 9.0)
			if mb.position.distance_squared_to(bc) <= NUMBER_R * NUMBER_R:
				value = sec + 12
				value_changed.emit()
				return
			bc = center + dir * (radius - 30.0)
			if mb.position.distance_squared_to(bc) <= NUMBER_R * NUMBER_R:
				value = sec
				value_changed.emit()
				return
		else:
			var sec := roundi(ang * 10.0 / TAU)
			if sec == 10:
				sec = 0
			var dir := Vector2.from_angle(sec / 10.0 * TAU - TAU/4.0)
			var bc := center + dir * (radius - 9.0)
			if mb.position.distance_squared_to(bc) <= NUMBER_R * NUMBER_R:
				value = value - (value % 10) + sec
				value_changed.emit()
				return
			sec = roundi(ang * 6.0 / TAU)
			if sec == 6:
				sec = 0
			dir = Vector2.from_angle(sec / 6.0 * TAU - TAU/4.0)
			bc = center + dir * (radius - 30.0)
			if mb.position.distance_squared_to(bc) <= NUMBER_R * NUMBER_R:
				value = value % 10 + sec * 10
				value_changed.emit()
				return
