@tool class_name EditorIcon extends Texture2D

@export_tool_button('Pick icon')
var __pick = pick_icon

@export var icon: StringName:
	get: return icon
	set(v):
		icon = v
		_update()

var _actual: Texture2D
static var _insts: Array[WeakRef]
static var _cleanup_queued := false

static var _theme: Theme
static func _static_init():
	if Engine.is_editor_hint():
		_theme = EditorInterface.get_editor_theme()
	else:
		_theme = load('res://icons.res')

func _init():
	_insts.push_back(weakref(self))

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if not _cleanup_queued:
			_cleanup_queued = true
			_cleanup_weaks.call_deferred()

static func _cleanup_weaks():
	_cleanup_queued = false
	var idx := 0
	while idx < _insts.size():
		if _insts[idx].get_ref() == null:
			_insts.remove_at(idx)
		else:
			idx += 1

func _update():
	if _actual:
		_actual.changed.disconnect(_icon_changed)
	_actual = _theme.get_icon(icon, &'EditorIcons')
	_actual.changed.connect(_icon_changed)
	emit_changed()

func _get_rid():
	if _actual:
		return _actual.get_rid()
	return RID()

func _get_width():
	if _actual:
		return _actual.get_width()
	return 0

func _get_height():
	if _actual:
		return _actual.get_height()
	return 0

func _is_pixel_opaque(x, y):
	if _actual:
		return _actual._is_pixel_opaque(x, y)
	return false

func _has_alpha():
	if _actual:
		return _actual.has_alpha()
	return false

func _icon_changed():
	emit_changed()

func pick_icon():
	var theme := EditorInterface.get_editor_theme()
	var icons := theme.get_icon_list(&'EditorIcons')
	var dialog := Window.new()
	dialog.title = 'Select icon'
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	dialog.add_child(panel)
	var items := ItemList.new()
	items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items.max_columns = 0
	items.icon_mode = ItemList.ICON_MODE_TOP
	items.same_column_width = true
	items.fixed_icon_size = Vector2i(32, 32)
	items.item_activated.connect(func(idx: int):
		icon = icons[idx]
		dialog.queue_free()
	)
	for icn in icons:
		items.add_item(icn, theme.get_icon(icn, &'EditorIcons'))
	panel.add_child(items)
	dialog.close_requested.connect(dialog.queue_free)
	EditorInterface.popup_dialog_centered(dialog, Vector2i(700, 400))
