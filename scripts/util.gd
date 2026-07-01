class_name Util extends Object

static func clear_children(node: Node):
	for idx in range(node.get_child_count()):
		node.get_child(0).free()
