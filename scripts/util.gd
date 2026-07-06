class_name Util extends Object

static func clear_children(node: Node):
	for idx in range(node.get_child_count()):
		node.get_child(0).free()

static func format_time(mins: int) -> String:
	var secs := mins % 60
	mins /= 60
	return '%02d:%02d' % [mins, secs]
