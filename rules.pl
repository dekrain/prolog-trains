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
	route_has_bidi(R, From, To).

route_has_bidi([A, B | _], A, B).
route_has_bidi([B, A | _], A, B).
route_has_bidi([_ | R], A, B) :- route_has_bidi(R, A, B).

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
