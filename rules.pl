road_between(X, Y) :- road(X, Y, _).
road_between(X, Y) :- road(Y, X, _).

reload_db :-
	abolish(station/1),
	abolish(station_xy/3),
	abolish(station_color/4),
	abolish(station_shape/2),
	abolish(road/3),
	abolish(schedule/1),
	abolish(schedule_route/2),
	!,
	consult(db).
