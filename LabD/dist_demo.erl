-module (dist_demo).
-compile(export_all).

start(Node) ->
    spawn(Node, fun() ->
			loop() end).

setupNodes() ->
    Nodes = nodes(),
    S = node(),
    [rpc:call(Node,?MODULE,fun start/1,[user, S, []]) ||Node <- Nodes].

rpc(Pid, M, F, A) ->
    Pid ! {rpc, self(), M, F, A},
    receive
	{Pid, Res} ->
	    Res
    end.

loop() ->
    receive
	{rpc, Pid, M, F, A} ->
	    Pid ! {self(), (catch apply(M, F, A))},
	    loop()
    end.
