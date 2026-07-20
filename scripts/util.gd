class_name Util extends Object

static func clear_children(node: Node):
	for idx in range(node.get_child_count()):
		node.get_child(0).free()

static func set_parent(node: Node, parent: Node):
	var par := node.get_parent()
	if par == parent:
		return
	if par != null:
		par.remove_child(node)
	if parent != null:
		parent.add_child(node)

static func format_time(mins: int) -> String:
	var secs := mins % 60
	mins /= 60
	return '%02d:%02d' % [mins, secs]

const DAY := 24*60

## Apply an offset to a time point, wrapping around day turn-over.
static func time_add(time: int, offset: int) -> int:
	time += offset
	if time >= DAY:
		time -= DAY
	return time

## Return the duration between two time points, handling day wrapping
## when the second argument is less than first.
static func time_diff(from: int, to: int) -> int:
	var diff := to - from
	if diff < 0:
		diff += DAY
	return diff

static func pl_call_function(pl: Prologot, predicate: String, args: Array) -> Variant:
	var res = pl.call_function(predicate, args)
	if res == null:
		push_error('Error calling function: ', pl.get_last_error())
	return res
