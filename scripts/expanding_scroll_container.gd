@tool class_name ExpandingScrollContainer extends ScrollContainer
## Stop gap/polyfil for expanding [ScrollContainer] until [b]4.7[/b].

@export var max_size: Vector2:
	get: return max_size
	set(v):
		max_size = v
		queue_sort()

func _notification(what):
	if what == NOTIFICATION_PRE_SORT_CHILDREN:
		_update_minimum_size()

func _update_minimum_size():
	if not is_node_ready():
		return
	var child := get_child(0) as Control
	var size := child.get_combined_minimum_size() if child != null else Vector2()
	if max_size.x > 0 and size.x > max_size.x:
		size.x = max_size.x
	if max_size.y > 0 and size.y > max_size.y:
		size.y = max_size.y
	custom_minimum_size = size
