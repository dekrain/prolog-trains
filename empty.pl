% station(name)
:- dynamic station/1.
% station_xy(name, X, Y)
:- dynamic station_xy/3.
% station_color(name, R, G, B)
:- dynamic station_color/4.
% station_shape(name, Vertices)
:- dynamic station_shape/2.
% road(from_station, to_station, Q)
:- dynamic road/3.
% schedule(name)
:- dynamic schedule/1.
% schedule_route(name, Stations)
:- dynamic schedule_route/2.
% schedule_timings(name, RoadDeltas)
:- dynamic schedule_timings/2.
% schedule_run(name, From, To, StartTime)
:- dynamic schedule_run/4.
