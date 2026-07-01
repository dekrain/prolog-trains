@tool class_name MapView extends Node2D

signal local_transform_changed

func _ready():
	set_notify_local_transform(true)

func _notification(what):
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		local_transform_changed.emit()
