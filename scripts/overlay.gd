class_name ScreenOverlay extends Panel

signal clicked

func _gui_input(event):
	if event is InputEventMouseButton:
		clicked.emit()
