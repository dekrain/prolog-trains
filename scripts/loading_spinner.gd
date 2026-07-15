@tool
class_name LoadingSpinner extends Control

@export var spinner_size := 30.0

var _time: float = 0.0

func _get_minimum_size() -> Vector2:
	return Vector2(spinner_size, spinner_size)

func _process(delta: float):
	_time += delta
	_time = fmod(_time, 1.0)
	queue_redraw()

func _draw():
	var radius := spinner_size * 0.5
	var center := Vector2(radius, radius)
	radius -= 1.5
	var ang0 := _time * TAU
	var ang1 := ang0 + TAU * 0.2
	draw_circle(center, radius, Color.DIM_GRAY, false, 3)
	draw_arc(center, radius, ang0, ang1, 16, Color.WHITE, 3)
