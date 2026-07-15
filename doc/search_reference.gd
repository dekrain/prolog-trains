## Pseudocode search algorithm implementation

class FoundRoute:
	var path: Array[RouteStop]
	var score: float

class RouteStop:
	var station: Station
	var time: int

class StationRoute:
	var schedule: Schedule
	var route: Array[RouteStop]

func station_stop_routes(station: Station, exculude_schedule: Schedule) -> Array[StationRoute]
func station_stop_best_routes(station: Station, exculude_schedule: Schedule, from_time: int) -> Array[StationRoute]

class PathItem:
	var cost: float
	# variant: ride
	var schedule: Schedule
	var from: Station
	var to: Station
	# variant: wait
	pass

class MapKey:
	var station: Station
	# Start time for current key node
	var start_time: int
	var visited_key_nodes: int
class MapState:
	var cost: float
	var time: int
	var path: Stack[PathItem]
var _route_map: Dictionary[MapKey, MapState]
class KeyPointKey:
	var start_time: int
	var vkp: int
# key_point --> finished_time
var _route_progress: Dictionary[KeyPointKey, int]

class QueueItem extends PriorityQueueItem:
	var station: Station
	var time: int
	var start_time: int
	var vkp: int
	var remaing_kps: Array[Station]
	var cost: float
	var route_schedule: Schedule
	var remaing_route: Array[RouteStop]
	var path: Stack[PathItem]

	func _weight() -> float:
		return cost

func find_routes(t_start: int, t_end: int, travel: Array[Station], limit: int) -> Array[FoundRoute]:
	var ss := SearchState.new(PriorityQueue.new(), [], limit)
	_route_map.clear()
	_route_progress.clear()
	setup_key_points(ss, 0, travel, t_start, t_end, 0.0, [])
	find_routes_loop(ss)
	return ss.results

class SearchState:
	var queue: PriorityQueue[QueueItem]
	var results: Array[FoundRoute]
	var limit: int

## Set t_end to -1 to disable end bound and instead add waiting cost.
func setup_key_points(ss: SearchState, vkp: int, kps: Array[Station], t_start: int, t_end: int, cost: float, path: Stack[PathItem]):
	var start := kps[0]
	var rem_kps := kps.slice(1)
	var start_points: Array[StationRoute]
	if t_end != -1:
		start_points = station_stop_routes(start, null).filter(
			func(route): return time_betwen(t_start, t_end, route.route[0].time))
	else:
		start_points = station_stop_best_routes(start, null, t_start)

	var wait_since := t_start if t_end == -1 else -1
	for sp in start_points:
		var start := sp.route[0]
		var new_path := path
		var new_cost := cost
		_route_progress[KeyPointKey.new(start.time, vkp)] = -1
		if wait_since != -1:
			var dt := time_delta(wait_since, start.time)
			var wait_cost := cost_of_wait()
			# TODO: Add cost of switch only when not the same route
			wait_cost += cost_of_switch()
			new_path = [PathItem.new_wait(wait_cost)] + path
			new_cost = cost + wait_cost
		process_route_segment_start(ss, QueueItem.new(start.station, start.time, start.time, vkp, rem_kps, new_cost, sp.schedule, sp.route.slice(1), new_path))

func process_route_segment_start(ss: SearchState, qitem: QueueItem):
	_route_map[MapKey.new(qitem.station, qitem.start_time, qitem.vkp)] = MapState.new(qitem.cost, qitem.time, qitem.path)
	process_route_segment(ss, qitem)

func process_route_segment(ss: SearchState, qitem: QueueItem):
	if !qitem.remaining_route.is_empty():
		var hop := qitem.remainig_route[0]
		var rest := qitem.remainig_route.slice(1)
		var dt := time_delta(qitem.time, hop.time)
		var seg_cost := cost_of_road(qitem.station, hop.station)
		# Reuse same QueueItem
		qitem.path = [PathItem.new_ride(qitem.route_schedule, qitem.station, hop.station, seg_cost)] + qitem.path
		qitem.station = hop.station
		qitem.time = hop.time
		# qitem.start_time unchanged
		# qitem.vkp unchanged
		# qitem.remaining_kps unchanged
		qitem.cost += seg_cost
		# qitem.route_schedule unchanged
		qitem.remaining_route = rest
		ss.q.add(qitem)

func find_routes_loop(ss: SearchState):
	while !ss.q.is_empty():
		# Get next item with minimal cost
		var qitem := ss.q.pop_min()
		# Check if a better path was found
		var kpk := KeyPointKey.new(qitem.start_time, qitem.vkp)
		if _route_progress[kpk] != -1:
			continue
		var mapk := MapKey.new(qitem.station, qitem.start_time, qitem.vkp)
		if mapk in _route_map:
			continue
		_route_map[mapk] = MapState.new(qitem.cost, qitem.time, qitem.path)
		# Check if key point reached
		if qitem.station == qitem.remaining_kps[0]:
			_route_progress[kpk] = qitem.time
			# qitem.station unchanged
			# qitem.time unchanged
			# qitem.start_time discarded
			qitem.vkp += 1
			# qitem.remaining_kps unchanged
			# qitem.cost unchanged
			# qitem.route_schedule discarded
			# qitem.remaining_route discarded
			# qitem.path unchanged
			if qitem.remaining_route.size() == 1:
				# Found complete path
				finalize_path(ss, qitem.path, qitem.cost)
				if ss.limit == 0:
					# All requested paths found
					return
			else:
				setup_key_points(ss, qitem.vkp, qitem.remaining_kps, qitem.time, -1, qitem.cost, qitem.path)
			continue
		# Find first forward & reverse route for each other schedule.
		# Do it first, because process_route_segment modifies qitem.
		for route in station_stop_best_routes(qitem.station, qitem.current_schedule, qitem.time):
			var dt := time_delta(qitem.time, route.route[0].time)
			var wait_cost := cost_of_switch() + cost_of_wait()
			process_route_segment(ss, QueueItem.new(qitem.station, route.route[0].time, qitem.start_time, qitem.vkp, qitem.remaing_kps, qitem.cost + wait_cost, route.schedule, route.route.slice(1), [PathItem.new_wait(wait_cost)] + qitem.path))
		process_route_segment(ss, qitem)

func finalize_path(ss: SearchState, path: Stack[PathItem], cost: float):
	var f_path := process_path(path)
	ss.results.append(FoundRoute.new(path, cost))
	ss.limit -= 1
