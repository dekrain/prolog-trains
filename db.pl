% station(name)
:- dynamic station/1.
station(javtyn).
station(epkgys).
station(dsijis).
station(hshbyj).
station(utookp).
station(wltjpt).
station(orofhc).
station(wegkui).
station(kbxthp).
station(lwspoc).

% station_xy(name, X, Y)
:- dynamic station_xy/3.
:- discontiguous station_xy/3.
% station_color(name, R, G, B)
:- dynamic station_color/4.
:- discontiguous station_color/4.
% station_shape(name, Vertices)
:- dynamic station_shape/2.
:- discontiguous station_shape/2.
station_xy(javtyn, 107.207, -90.16).
station_color(javtyn, 177, 133, 123).
station_shape(javtyn, [1.697, 9.886, -10.523, 4.499, 6.765, -9.228, 10.463, -4.973]).
station_xy(epkgys, 191.852, 12.125).
station_color(epkgys, 90, 160, 149).
station_shape(epkgys, [0.345, 9.809, -9.493, -6.404, -1.872, -9.815, -0.124, -11.29, 8.343, -6.528, 9.863, -0.407]).
station_xy(dsijis, 96.332, 130.66).
station_color(dsijis, 202, 121, 79).
station_shape(dsijis, [8.458, 7.587, -2.701, -11.068, -2.64, -11.175, 4.951, -9.931, 7.595, -7.774]).
station_xy(hshbyj, -73.879, 181.035).
station_color(hshbyj, 180, 125, 156).
station_shape(hshbyj, [9.04, 2.861, -8.15, -8.134, -1.65, -10.896]).
station_xy(utookp, -176.75, 173.773).
station_color(utookp, 166, 127, 187).
station_shape(utookp, [4.033, 8.671, -11.178, 1.61, -0.933, -9.974]).
station_xy(wltjpt, -236.887, 133.273).
station_color(wltjpt, 142, 137, 194).
station_shape(wltjpt, [9.753, 1.288, -3.776, -9.308, 9.136, -6.367]).
station_xy(orofhc, -238.504, 309.244).
station_color(orofhc, 186, 128, 120).
station_shape(orofhc, [8.84, 3.084, 0.068, 9.815, -11.035, -0.011, -9.098, -2.354, -4.18, -8.591, -0.933, -10.198]).
station_xy(wegkui, -23.56, 311.881).
station_color(wegkui, 168, 138, 119).
station_shape(wegkui, [1.764, 10.064, -10.19, 3.727, -4.877, -8.43, -2.406, -11.274, 5.621, -9.077]).
station_xy(kbxthp, -0.255, -193.006).
station_color(kbxthp, 130, 153, 123).
station_shape(kbxthp, [-0.521, 10.306, -5.107, 9.795, -6.406, 8.991, -11.231, -2.454, -3.289, -9.114, 9.116, -2.19]).
station_xy(lwspoc, 319.793, -192.535).
station_color(lwspoc, 104, 158, 134).
station_shape(lwspoc, [-7.078, 9.067, -9.691, -3.429, 2.491, -9.382, 10.506, -0.971]).

% road(from_station, to_station, Q)
:- dynamic road/3.
road(utookp, hshbyj, 0.7).
road(epkgys, dsijis, 1.0).
road(epkgys, javtyn, 1.0).
road(kbxthp, lwspoc, 0.0).

% schedule(name)
:- dynamic schedule/1.
schedule(qhokrz).
schedule(xnifin).
schedule(acyarh).
schedule(ugfnfx).

% schedule_route(name, Stations)
:- dynamic schedule_route/2.
schedule_route(qhokrz, [utookp, hshbyj]).
schedule_route(xnifin, [javtyn, epkgys, dsijis]).
schedule_route(acyarh, [kbxthp, lwspoc]).
schedule_route(ugfnfx, [epkgys, javtyn]).

% schedule_timings(name, RoadDeltas)
:- dynamic schedule_timings/2.
schedule_timings(qhokrz, [2]).
schedule_timings(xnifin, [13, 15]).
schedule_timings(acyarh, [64]).
schedule_timings(ugfnfx, [13]).

% schedule_run(name, From, To, StartTime)
:- dynamic schedule_run/4.
schedule_run(qhokrz, utookp, hshbyj, 720).
schedule_run(qhokrz, utookp, hshbyj, 839).
schedule_run(qhokrz, hshbyj, utookp, 237).
schedule_run(qhokrz, hshbyj, utookp, 828).
schedule_run(xnifin, javtyn, dsijis, 780).
schedule_run(xnifin, dsijis, javtyn, 960).
schedule_run(ugfnfx, javtyn, epkgys, 488).
