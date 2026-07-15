@tool extends PanelContainer

enum HSide {
	Left,
	Center,
	Right,
}

@export var margin: float = 20.0:
	get: return margin
	set(v):
		margin = v
		_interpolate()
@export var side: HSide = HSide.Left:
	get: return side
	set(v):
		side = v
		_interpolate()
@export_range(0.0, 5.0, 0.1, 'suffix:s') var duration: float = 2.0

var tween: Tween

func _interpolate():
	if tween != null:
		tween.kill()
	var anchor: float
	var pos := position.x
	match side:
		HSide.Left:
			grow_horizontal = Control.GROW_DIRECTION_END
			anchor = 0.0
		HSide.Center:
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			anchor = 0.5
		HSide.Right:
			grow_horizontal = Control.GROW_DIRECTION_BEGIN
			anchor = 1.0
	position.x = pos
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, ^':offset_top', margin, duration)
	tween.tween_property(self, ^':offset_left', margin, duration)
	tween.tween_property(self, ^':offset_right', -margin, duration)
	tween.tween_property(self, ^':anchor_left', anchor, duration)
	tween.tween_property(self, ^':anchor_right', anchor, duration)
