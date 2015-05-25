-module(crawl).
-compile(export_all).

crawl(Url, D) ->
    Pages = follow(D, [{Url, undefined}]), 
    [{U, Body} || {U, Body} <- Pages,
		   Body /= undefined].

follow(0, KVs) ->
    KVs;
follow(D, KVs) ->
    follow(D-1, map_reduce:map_reduce_par(fun map/2, 20, fun reduce/2, 1, KVs)).

map(Url, undefined) ->
    Body = fetch_url(Url),
    [{Url, Body}] ++ [{U, undefined} || U <- find_urls(Url,Body)];
map(Url, Body) ->
    [{Url, Body}].

reduce(Url, Bodies) ->
    case [B || B <- Bodies, B /= undefined] of
	[] ->
	    [{Url, undefined}];
	[Body] ->
	    [{Url, Body}]
    end.

fetch_url(Url) ->
    case httpc:request(Url) of
	{ok, {_, Headers, Body}} ->
	    Body;
	_ ->
	    ""
    end.

find_urls(Url, Html) ->
    Lower = string:to_lower(Html),
    Absolute = case re:run(Lower, "http://.*?(?=\")", [global]) of
		   {match, Locs} ->
		       [lists:sublist(Html, Pos+1, Len) || [{Pos, Len}]<- Locs];
		   _ ->
		       []
	       end,
    Relative = case re:run(Lower, "href *=*\"(?!http:).*?(?=\")", [global]) of
		   {match, RLocs} ->
		       [lists:sublist(Html, Pos+1, Len) || {Pos, Len} <- RLocs];
		   _ ->
		       []
	       end,
    Absolute ++ [Url ++ "/" ++ lists:dropwhile(fun(Char) -> Char==$/ end, 
					       tl(lists:dropwhile(fun(Char) -> Char/=$" end, R)))
		|| R <- Relative].


saveFile() ->
    dets:open_file(web, [{file, "web.dat"}]),
    [dets:insert(web, {U, B})||{U, B}<- crawl("http://www.cse.chalmers.se", 1)],
    dets:close(web).
