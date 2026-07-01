@tool extends EditorScript

# Create the icons.res theme for editor icons
func _run():
	var theme := Theme.new()
	for weak in EditorIcon._insts:
		var inst: EditorIcon = weak.get_ref()
		if inst != null:
			print('Found: ' + str(inst))
			theme.set_icon(inst.icon, &'EditorIcons', inst._actual)
	ResourceSaver.save(theme, 'res://icons.res', ResourceSaver.FLAG_COMPRESS)
	theme.take_over_path('res://icons.res')
