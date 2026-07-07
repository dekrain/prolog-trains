road_between(X, Y) :- road(X, Y, _).
road_between(X, Y) :- road(Y, X, _).

road_between_q(X, Y, Q) :- road(X, Y, Q).
road_between_q(X, Y, Q) :- road(Y, X, Q).

reload_db :-
	abolish(station/1),
	abolish(station_xy/3),
	abolish(station_color/4),
	abolish(station_shape/2),
	abolish(road/3),
	abolish(schedule/1),
	abolish(schedule_route/2),
	abolish(schedule_timings/2),
	abolish(schedule_run/4),
	!,
	consult(db).

%! road_part_of_schedule(+From, +To) is semidet
road_part_of_schedule(From, To) :-
	road_between(From, To),
	schedule_route(_, R),
	(nextto(From, To, R) ; nextto(To, From, R)).

%! compute_route_timings(+Schedule, -Timings)
compute_route_timings(Schedule, Timings) :-
	schedule_route(Schedule, Route),
	compute_route_timings_(Route, Timings).

compute_route_timings_([_], []).

compute_route_timings_([], _) :- fail.
compute_route_timings_([_, _], []) :- fail.

compute_route_timings_([From, To | SRest], [Time | TRest]) :-
	compute_route_segment_timing(From, To, Time),
	compute_route_timings_([To | SRest], TRest).

compute_route_segment_timing(From, To, Time) :-
	road_between_q(From, To, Q),
	station_xy(From, X0, Y0),
	station_xy(To, X1, Y1),
	Dx is abs(X1 - X0),
	Dy is abs(Y1 - Y0),
	Dist is sqrt(Dx*Dx + Dy*Dy),
	Time is 2**(1.0 - Q) * Dist * 0.1.


%! schedule_for_station(+Station, -Schedule, -Index) is nondet.
%! schedule_for_station(-Station, +Schedule, +Index) is semidet.
schedule_for_station(Station, Schedule, Index) :-
	schedule_route(Schedule, Route),
	nth0(Index, Route, Station).

%! station_stop(+Station, -Schedule, -Time, -Reverse) is semidet.
station_stop(Station, Schedule, Time, Reverse) :-
	schedule_for_station(Station, Schedule, Index),
	schedule_timings(Schedule, Timings),
	schedule_run(Schedule, S, E, Offset),
	schedule_endpoints(Schedule, S, E, Reverse),
	% !,
	accumulate_timings(Timings, Offset, Index, Reverse, Time).

schedule_endpoints(Schedule, Start, End, Reverse) :-
	schedule_route(Schedule, Route),
	route_endpoints(Route, Start, End, Reverse).

route_endpoints(Route, Start, End, 0) :-
	nth0(0, Route, Start),
	last(Route, End).
route_endpoints(Route, Start, End, 1) :-
	nth0(0, Route, End),
	last(Route, Start).

accumulate_timings(Timings, Offset, Index, 0, Sum) :-
	sum_prefix(Timings, Offset, Index, Sum).

accumulate_timings(Timings, Offset, Index, 1, Sum) :-
	sum_suffix(Timings, Offset, Index, Sum).

sum_prefix(_, Acc, 0, Acc).
sum_prefix([H|T], Acc, Count, Sum) :-
	Cnext is Count - 1,
	Anext is Acc + H,
	!,
	sum_prefix(T, Anext, Cnext, Sum).

sum_suffix(Timings, Offset, Index, Sum) :-
	list_skip(Timings, Index, Slice),
	lists:sum_list(Slice, Offset, Sum).

list_skip(L, 0, L).
list_skip([_|T], N, S) :-
	D is N - 1,
	list_skip(T, D, S).
