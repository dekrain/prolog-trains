:- use_module(library(lists)).
:- use_module(library(heaps)).
:- use_module(library(aggregate)).
:- use_module(library(error)).

road_between(X, Y) :- road(X, Y, _).
road_between(X, Y) :- road(Y, X, _).

road_between_q(X, Y, Q) :- road(X, Y, Q).
road_between_q(X, Y, Q) :- road(Y, X, Q).

reload_db :-
	retractall(station(_)),
	retractall(station_xy(_, _, _)),
	retractall(station_color(_, _, _, _)),
	retractall(station_shape(_, _)),
	retractall(road(_, _, _)),
	retractall(schedule(_)),
	retractall(schedule_route(_, _)),
	retractall(schedule_timings(_, _)),
	retractall(schedule_run(_, _, _, _)),
	!,
	consult(db).

%! road_part_of_schedule(+From, +To) is semidet.
road_part_of_schedule(From, To) :-
	road_between(From, To),
	schedule_route(_, R),
	(nextto(From, To, R) ; nextto(To, From, R)).

%! compute_route_timings(+Schedule, -Timings) is det.
compute_route_timings(Schedule, Timings) :-
	schedule_route(Schedule, Route),
	compute_route_timings_(Route, Timings).

compute_route_timings_([], _) :- fail.
compute_route_timings_([_], T) :- !, T = [].

compute_route_timings_([From, To | SRest], Times) :-
	compute_route_segment_timing(From, To, Time),
	compute_route_timings_([To | SRest], Ts),
	!,
	Times = [Time | Ts].

compute_route_segment_timing(From, To, Time) :-
	road_between_q(From, To, Q),
	!,
	distance(From, To, Dist),
	% 1 u = 150 m
	% 10 u/min = 90 km/h best case, not accounting for time spent on stops
	Time is 2**(1.0 - Q) * Dist * 0.1.

%! distance(+From, +To, -Dist) is det.
distance(From, To, Dist) :-
	station_xy(From, X0, Y0),
	station_xy(To, X1, Y1),
	Dx is abs(X1 - X0),
	Dy is abs(Y1 - Y0),
	Dist is sqrt(Dx*Dx + Dy*Dy).


%! schedule_for_station(+Station, -Schedule, -Index) is nondet.
%! schedule_for_station(-Station, +Schedule, +Index) is semidet.
schedule_for_station(Station, Schedule, Index) :-
	schedule_route(Schedule, Route),
	nth0(Index, Route, Station).

%! station_stop(+Station, -Schedule, -Time, -Reverse) is nondet.
station_stop(Station, Schedule, Time, Reverse) :-
	% nondet -Schedule, -Index
	schedule_for_station(Station, Schedule, Index),
	% det -Timings
	schedule_timings(Schedule, Timings),
	% nondet -S, -E, -Offset
	schedule_run(Schedule, S, E, Offset),
	% det -Reverse
	schedule_endpoints(Schedule, S, E, Reverse),
	% det -Time
	accumulate_timings(Timings, Offset, Index, Reverse, Time).

%! station_stop_route(+Station, ?Schedule, -Route) is nondet.
% Finds routes for a given Station in Schedule. There's a Route returned
% for each defined run, both forward and reverse.
station_stop_route(Station, Schedule, Route) :-
	% nondet -Schedule, -Index
	schedule_for_station(Station, Schedule, Index),
	% ExclSchedule is either unbound or a schdule ID to exclude.
	% (not needed, can use dif).
	%Schedule \== ExclSchedule,
	% det -Fpath, -Rpath
	schedule_route_from_idx(Schedule, Index, Fpath, Rpath),
	% nondet -S, -E, -Offset
	schedule_run(Schedule, S, E, Offset),
	% det -Reverse
	schedule_endpoints(Schedule, S, E, Reverse),
	% det -Path
	select_fw_rev(Fpath, Rpath, Reverse, Path),
	% det -Route
	offset_stops(Path, Offset, Route).

%! station_stop_best_route(+Station, ?Schedule, +Time, -Forward, -Reverse) is nondet.
% Finds the best route for a given Schedule, going Forward and in Reverse.
% Only the route for which the train arrives the soonest since Time on
% the Station is returned.
%
% In case schedule only has plans defined in one direction,
% returns [] in the corresponding output. Fails for empty plans.
station_stop_best_route(Station, Schedule, T, Fw, Rev) :-
	% nondet -Schedule, -Index
	schedule_for_station(Station, Schedule, Index),
	% Assert there's at least one run defined for this schedule (semidet).
	once(schedule_run(Schedule, _, _, _)),
	% det -Fpath, -Rpath
	schedule_route_from_idx(Schedule, Index, Fpath, Rpath),
	% det -S, -E
	schedule_endpoints(Schedule, S, E, 0),
	station_best_route_sel_(Schedule, S, E, T, Fpath, Fw),
	station_best_route_sel_(Schedule, E, S, T, Rpath, Rev).

station_best_route_sel_(Schedule, S, E, T, Path, Route) :-
	% semidet -Offset
	aggregate(min(Wait, Offset), (
		% nondet -S, -E, -Offset
		schedule_run(Schedule, S, E, Offset),
		% det -Wait
		time_delta(T, Offset, Wait)
	), min(_, Offset)),
	!,
	% det -Route
	offset_stops(Path, Offset, Route).

station_best_route_sel_(_, _, _, _, _, Route) :-
	% If no run found, return empty route.
	Route = [].

%! schedule_endpoints(+Schedule, +Start, +End, -Reverse) is det.
schedule_endpoints(Schedule, Start, End, Reverse) :-
	schedule_route(Schedule, Route),
	route_endpoints(Route, Start, End, Reverse).

route_endpoints(Route, Start, End, 0) :-
	nth0(0, Route, Start),
	last(Route, End),
	!.
route_endpoints(Route, Start, End, 1) :-
	nth0(0, Route, End),
	last(Route, Start),
	!.

%! schedule_route_from(+Schedule, +Station, -Forward, -Reverse) is det.
% Returns remaining paths of the form stop(Station, Time) in
% Schedule, starting from Station. First stop is for Station,
% which includes its time since start of the run.
% All Times are relative to run start.
schedule_route_from(Schedule, Station, Fpath, Rpath) :-
	schedule_for_station(Station, Schedule, Idx),
	schedule_route_from_idx(Schedule, Idx, Fpath, Rpath).

%! schedule_route_from(+Schedule, +StationIdx, -Forward, -Reverse) is det.
% Like schedule_route_from, but with Index of the starting Station provided instead.
schedule_route_from_idx(Schedule, Idx, Fpath, Rpath) :-
	schedule_route(Schedule, Stations),
	schedule_timings(Schedule, Timings),
	% Stations = [S0, S1, ..., Sn]
	% Timings = [T1, T2, ..., Tn]
	% Idx = 0 -> Fpath = [stop(S0, 0), stop(S1, T1), stop(S2, T1+T2), ..., stop(Sn, T1+T2+...+Tn)], Rpath = [stop(S0, Tn+...+T2+T1]
	% Idx = 1 -> Fpath = [stop(S1, T1), stop(S2, T1+T2), ..., stop(Sn, T1+T2+...+Tn)], Rpath = [stop(S1, Tn+...+T2), stop(S0, Tn+...+T2+T1)]
	% Idx = n -> Fpath = [stop(Sn, T1+T2+...+Tn)], Rpath = [stop(Sn, 0), stop(S{n-1}, T{n-1}), ..., stop(S1, Tn+...+T2), stop(S0, Tn+...+T2+T1)]
	schedule_route_fw_(Stations, Timings, Idx, Fpath),
	schedule_route_rev_(Stations, Timings, Idx, Rpath).

select_fw_rev(F, _R, 0, Res) :- !, Res = F.
select_fw_rev(_F, R, 1, Res) :- !, Res = R.

%! accumulate_timings(+Timings, +Offset, +Index, +Reverse, -Time) is det.
accumulate_timings(Timings, Offset, Index, 0, Sum) :-
	sum_prefix(Timings, Offset, Index, Sum).

accumulate_timings(Timings, Offset, Index, 1, Sum) :-
	sum_suffix(Timings, Offset, Index, Sum).

sum_prefix(_, Acc, 0, Sum) :- !, Sum = Acc.
sum_prefix([H|T], Acc, Count, Sum) :-
	Cnext is Count - 1,
	Anext is Acc + H,
	sum_prefix(T, Anext, Cnext, Sum).

sum_suffix(Timings, Offset, Index, Sum) :-
	list_skip(Timings, Index, Slice),
	lists:sum_list(Slice, Offset, Sum).

list_skip(L, 0, S) :- !, S = L.
list_skip([_|T], N, S) :-
	D is N - 1,
	list_skip(T, D, S).

schedule_route_fw_(S, T, I, P) :- schedule_route_fw_(S, T, 0, I, P).
schedule_route_fw_([S], [], A, 0, P) :-
	!,
	P = [stop(S, A)].
schedule_route_fw_([S|Ss], [T|Ts], A, 0, P) :-
	!,
	P = [stop(S, A)|Ps],
	Ar is A + T,
	schedule_route_fw_(Ss, Ts, Ar, 0, Ps).
schedule_route_fw_([_|Ss], [T|Ts], A, I, P) :-
	Ar is A + T,
	Ir is I - 1,
	schedule_route_fw_(Ss, Ts, Ar, Ir, P).

schedule_route_rev_(S, T, I, P) :-
	length(T, Nt),
	reverse(S, Sr),
	reverse(T, Tr),
	Ir is Nt - I,
	schedule_route_fw_(Sr, Tr, 0, Ir, P).

offset_stops([], _Offset, R) :- !, R = [].
offset_stops([P|Ps], Offset, R) :-
	P = stop(S, T),
	!,
	Tr is Offset + T,
	R = [stop(S, Tr)|Rs],
	offset_stops(Ps, Offset, Rs).

%! find_routes(+TStart, +TEnd, +Travel, +Limit, -Routes) is det.
% Finds routes starting in the interval from TStart to TEnd, which are
% a supersequence of Travel (i.e. all stations in Travel occur in order),
% with maximum of Limit results. The routes are sorted from best to worst.
%
% Routes is a list of terms route(Path, Score), where Path is a list of terms stop(Station, Time), and score is the final cost of the path.
% Routes are returned with increasing cost (lower cost is better).
find_routes(TStart, TEnd, Travel, Limit, Routes) :-
	dedup_seq(Travel, TravelD),
	(	TravelD = [Start | Rest],
		Rest = [_|_]
	->	true
	;	throw(error(domain_error(multiple_distinct_stations, Travel), "Travel must include multiple distinct stations"))
	),
	% Only enter search if a positive number of results was requested.
	must_be(nonneg, Limit),
	Limit > 0,
	!,
	findall(route(Sched, R), (
		station_stop_route(Start, Sched, R),
		R = [stop(Start, T) | _],
		time_between(TStart, TEnd, T)
	), StartPoints),
	retractall(route_map_(_, _, _)),
	call_cleanup(
		(	empty_heap(Qi),
			setup_start_points(StartPoints, Rest, Qi, Q),
			find_routes_step(Limit, Q, Routes)
		),
		retractall(route_map_(_, _, _))
	).

find_routes(_, _, _, 0, []).

%! time_between(+Start, +End, +Time) is semidet.
time_between(Start, End, Time) :-
	Start =< End,
	!,
	Time >= Start,
	Time =< End.

time_between(Start, End, Time) :-
	% Start > End,
	(Time =< End;
	Time >= Start).

%! time_delta(+From, +To, -Delta) is det.
time_delta(From, To, Delta) :-
	From =< To,
	!,
	Delta is To - From.

time_delta(From, To, Delta) :-
	% From > To
	Delta is To + (1440 - From).

assert_time(Time) :-
	must_be(between(0, 1440), Time).

:- thread_local route_map_/3.
% concept: route_map_(key(Station, StartTime, NumVisitedKeyNodes), found(Cost, Time, Path)).
% actual: route_map_(Station, StartTime, nVKN) :- visited.
%         route_map_(special(finished), StartTime, nVKN) :- best path found.

%find_routes_(P, KP, Lim, Res) :-

% --- Queue manipulation

%! append_pq(+Qin, +Qitem, -Qout) is det.
append_pq(Qin, search(St, T, SsT, VKP, KPs, C, S, R, P), Qout) :-
	% Good place to do typechecking on queue items
	must_be(atom, St),
	assert_time(T),
	assert_time(SsT),
	must_be(nonneg, VKP),
	must_be(list, KPs),
	must_be(float, C),
	must_be(atom, S),
	must_be(list, R),
	must_be(list, P),
	add_to_heap(Qin, C, search_h(St, T, SsT, VKP, KPs, S, R, P), Qout).

%! get_pq(+Qin, -Qitem, -Qout) is semidet.
get_pq(Qin, Qitem, Qout) :-
	Qitem = search(St, T, SsT, VKP, KPs, C, S, R, P),
	get_from_heap(Qin, C, search_h(St, T, SsT, VKP, KPs, S, R, P), Qout).

% --- Search algorithm

% Initial setup: first station
setup_start_points([], _, Qi, Qo) :- !, Qo = Qi.
setup_start_points([SP|SPs], KPs, Qi, Qo) :-
	SP = route(Sched, R),
	R = [stop(Start, T) | Rs],
	%assertz(route_map_(key(Start, 0), found(0, T, []))),
	Qitem = search(Start, T, T, 0, KPs, 0.0, Sched, Rs, [start(T)]),
	step_process_seg_start(Qitem, Qi, Qn),
	setup_start_points(SPs, KPs, Qn, Qo).

% Setup next key point
setup_key_points([], _, _, _, _, _, _, _, Q, Qq) :- !, Qq = Q.
setup_key_points([[]|RTs], Sched, VKP, KPs, T, C, P, Cr, Q, Qq) :-
	!, setup_key_points(RTs, Sched, VKP, KPs, T, C, P, Cr, Q, Qq).

setup_key_points([R|RTs], Sched, VKP, KPs, T, C, P, CurRoute, Q, Qq) :-
	R = [stop(Start, StartT) | Rs],
	(	CurRoute = [Sched, N|_], Rs = [N|_]
	->	% If continuing the current route, don't add any penalty.
		Pp = P,
		Cp = C
	;	time_delta(T, StartT, DT),
		cost_of(switch, SwC),
		cost_of(wait(DT), WrC),
		WC is SwC + WrC,
		Pp = [wait(DT, WC)|P],
		Cp is C + WC
	),
	Qitem = search(Start, StartT, StartT, VKP, KPs, Cp, Sched, Rs, Pp),
	step_process_seg_start(Qitem, Q, Qn),
	setup_key_points(RTs, Sched, VKP, KPs, T, C, P, CurRoute, Qn, Qq).

step_process_seg_start(Qitem, Q, Qq) :-
	Qitem = search(St, _, SsT, VKP, _, _, _, _, _),
	assertz(route_map_(St, SsT, VKP)),
	step_process_seg(Qitem, Q, Qq).

step_process_seg(Qitem, Q, Qq) :-
	Qitem = search(St, T, SsT, VKP, KPs, Cost, Sched, Rt, P),
	(	Rt = [stop(Hop, HopT) | Rr]
	->	time_delta(T, HopT, DT),
		distance(St, Hop, Rl),
		once(road_between_q(St, Hop, Rq)),
		cost_of(road(Rl, Rq, DT), SegCost),
		Pp = [ride(Sched, St, Hop, DT, SegCost) | P],
		NewCost is Cost + SegCost,
		append_pq(Q, search(Hop, HopT, SsT, VKP, KPs, NewCost, Sched, Rr, Pp), Qq)
	;	Qq = Q
	).

% find_routes_step(+Lim, +Q, -Res) is det.
find_routes_step(0, _, Res) :- !, Res = [].
find_routes_step(Lim, Qa, Res) :-
	(	get_pq(Qa, Qitem, Qb)
	->	Qitem = search(St, T, SsT, VKP, KPs, C, Sched, Rt, P),
		(	% Check if node has been visited or best path found
			(	route_map_(St, SsT, VKP)
			;	route_map_(special(finished), SsT, VKP)
			)
		->	find_routes_step(Lim, Qb, Res)
		;	% Good to go. First, let's add this stop to the map.
			assertz(route_map_(St, SsT, VKP)),
			% Check if a key point has been reached
			(	KPs = [KP | KPr],
				St = KP
			->	assertz(route_map_(special(finished), SsT, VKP)),
				succ(VKP, NewVKP),
				(	KPr = []
				->	% Finish one route
					fin_path(P, Pres),
					succ(NewLim, Lim),
					Res = [route(Pres, C) | RRes],
					% Limit the number of returned paths
					(	NewLim = 0
					->	RRes = []
					;	find_routes_step(NewLim, Qb, RRes)
					)
				;	% More key points to go
					foldall(setup_key_points([Fw, Rev], NewSched, NewVKP, KPr, T, C, P, [Sched|Rt]),
						station_stop_best_route(St, NewSched, T, Fw, Rev),
						Qb, Qc),
					find_routes_step(Lim, Qc, Res)
				)
			;	% Continue current ride and consider train changes
				step_process_seg(Qitem, Qb, Qc),
				step_process_switches(Qitem, Qc, Qd),
				find_routes_step(Lim, Qd, Res)
			)
		)
	;	Res = [] % Queue is empty
	).

step_process_switches(Qitem, Q, Qq) :-
	Qitem = search(St, T, _, _, _, _, CurSched, _, _),
	foldall(step_process_switch_(Qitem, Sched, Fw, Rev), (
		dif(Sched, CurSched),
		station_stop_best_route(St, Sched, T, Fw, Rev)
	), Q, Qq).

step_process_switch_(Qitem, Sched, Fw, Rev, Q, Qq) :-
	step_process_switch__(Qitem, Sched, Fw, Q, Qn),
	step_process_switch__(Qitem, Sched, Rev, Qn, Qq).

step_process_switch__(Qitem, Sched, R, Q, Qq) :-
	Qitem = search(St, T, SsT, VKP, KPs, C, _, _, P),
	R = [stop(St, TSwitch) | Rs],
	time_delta(T, TSwitch, DT),
	cost_of(switch, SwC),
	cost_of(wait(DT), WrC),
	WC is SwC + WrC,
	Pp = [wait(DT, WC)|P],
	Cp is C + WC,
	step_process_seg(search(St, TSwitch, SsT, VKP, KPs, Cp, Sched, Rs, Pp), Q, Qq).

% TODO
fin_path(P, P).

/*find_routes_step(KP, Lim, Qa, Res) :-
		(	P = [ride(LastSched, _, _, _) | _]
		->	true
		;	true
		),
		findall(route(Sched, BT, Pp, Cp, Rs), (
			station_stop_route(St, Sched, LastSched, R),
			% LastSched is either an atom or unbound, so
			% this should correctly work in both cases.
			R = [stop(St, BT) | Rs],
			(	P = []
			->	Pp = P, Cp = C,
			;	time_delta(T, BT, DT),
				cost_of(switch, SwC),
				cost_of(wait(DT), WrC),
				WC is SwC + WrC,
				Pp = [wait(T, BT, WC)|P],
				Cp is C + WC
			)
		), OutPaths),
		step_process_paths(KP, Lim, St, Qrem, OutPaths, Res)

step_process_paths(KP, Lim, St, Q, Paths, Res) :-
	(	Paths = [route(Sched, BoardTime, P, C, [H|Hs])|Ps]
	->	step_process_route(KP, Lim, St, Q, Sched, BoardTime, C, P, H, Hs, Ps)
	;	Paths = [route(_, _, [])|Ps]
	->	step_process_paths(KP, Lim, Qitem, Q, Ps, Res)
	;	Paths = []
	->	find_routes_step(KP, Lim, Q, Res)
	).

step_process_route(KP, I, Lim, From, Q, Sched, Tp, Cp, Pp, Hop) :-
	Hop = stop(To, T),
	% FIXME
	distance(From, To, Rl),
	once(road_between(From, To, Rq)),
	time_diff(Tp, T, DT),
	cost_of(road(Rl, Rq, DT), Cr),
	C is Cp + Cr,
	MapKey = key(To, I),
	(	route_map_(MapKey, found(FC, FT, FP)),
		FC =< C
	->	true
	;	retractall(route_map_(MapKey, _)),
		assertz(route_map_(MapKey, found(C, T, P)))
	),
	queue_next__.*/

/*
For each key station in the travel path, we track
the best score path from it for each node.

All paths stem from a specific schedule. A change of train
is considered to incur an additional, fixed (in this model), cost,
plus a cost proportional to time waited for the change.

This cost is applied even if the station is a key station in requested
route. In such case, if all path have train switches there, the additional
cost will be equal among the alternatives.

The route is composed of path segments:
- ride(Schedule, FromSt, ToSt, Cost) - rides from station FromSt to ToSt on a Schedule, Cost is total cost from all traversed roads.
- wait(Cost) - switch train and wait, including when there's no wait time. Cost encompasses wait
time (with different scaling factor from rides), in addition to the fixed change cost.
*/

%! cost_of(+Segment, -Cost) is det.
% Compute the cost of a travel segment. Segment is one of:
% - road(Length, Quality, Time): segment traveled by train
% - wait(Time) - wait Time for a train to arrive
% - switch - cost added when switching trains. It is added to wait components in resulting path when a train switch occurs
cost_of(What, Cost) :-
	(	What = switch
	->	Cost = 20
	;	What = wait(T)
	->	Cost is T*10
	;	What = road(L, Q, T)
	% Relation between L and T gives us average speed.
	% Reminder: speed is in u/min = 150 m/min = 0.15*60 km/h = 9 km/h.
	% Comfortable speed depends on road quality.
	% For Q=1: between 72 km/h = 8 u/min and 94.5 km/h = 10.5 u/min.
	% For Q=0: between 31.5 km/h = 3.5 u/min and 54 km/h = 6 u/min.
	->	Spd is L/T,
		SpdLow is Q*8 + (1-Q)*3.5,
		SpdHi is Q*10.5 + (1-Q)*6,
		MidSpd is Spd - (SpdLow + SpdHi)/2,
		SpdRange is SpdHi - SpdLow,
		Cost is T*5 + 40*min(1, 1 + ((MidSpd + SpdRange)*(MidSpd - SpdRange)/(SpdRange*SpdRange)))
	).

dedup_seq(L, R) :-
	(	L = []
	->	R = []
	;	L = [H, H | T]
	->	dedup_seq([H|T], R)
	;	L = [H | T]
	->	R = [H | Rs],
		dedup_seq(T, Rs)
	).

% --- Debug utils
pprint_routes([]) :- !.
pprint_routes([R|Rs]) :-
	R = route(P, Cost),
	length(P, Len),
	format("Route (#~d, ~f):\n", [Len, Cost]),
	reverse(P, Pr),
	pprint_path(Pr),
	pprint_routes(Rs).

pprint_path([]) :- !.
pprint_path([P|Ps]) :-
	tab(4),
	write_term(P, [spacing(next_argument)]),
	(	Ps = []
	->	writeln(".")
	;	writeln(",")
	),
	pprint_path(Ps).
