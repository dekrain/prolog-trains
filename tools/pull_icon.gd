@tool extends EditorScript

func _run():
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
		var icon_name := icons[idx]
		var icon := theme.get_icon(icon_name, &'EditorIcons')
		EditorInterface.edit_resource(icon)
		#var save_dialog := EditorFileDialog.new()
		#save_dialog.access = FileDialog.ACCESS_RESOURCES
		#save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		#save_dialog.title = 'Save icon as'
		#save_dialog.current_file = icon_name + '.svg'
		#save_dialog.visibility_changed.connect(func():
		#	if not save_dialog.visible:
		#		save_dialog.queue_free()
		#)
		#save_dialog.file_selected.connect(func(path: String):
		#	ResourceSaver.save(icon, path)
		#)
		#EditorInterface.get_base_control().add_child(save_dialog)
		#save_dialog.popup_file_dialog()
		dialog.queue_free()
	)
	for icn in icons:
		items.add_item(icn, theme.get_icon(icn, &'EditorIcons'))
	panel.add_child(items)
	dialog.close_requested.connect(dialog.queue_free)
	EditorInterface.popup_dialog_centered(dialog, Vector2i(700, 400))
