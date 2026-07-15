@tool
class_name ClickablePanel extends PanelContainer

signal pressed

@export var theme_type := &'GridCell'

func _init():
	focus_mode = Control.FOCUS_ALL

func _ready():
	theme_type_variation = theme_type

func disable():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

func _notification(what):
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_FOCUS_ENTER:
		theme_type_variation = &'GridCellHighlight'
	elif what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_FOCUS_EXIT:
		if not has_focus():
			theme_type_variation = theme_type

func _gui_input(event: InputEvent):
	var mb := event as InputEventMouseButton
	if event.is_action_pressed("ui_accept") or (mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed):
		pressed.emit()
