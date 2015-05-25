-module (testingNodes).
-compile(export_all).

answerToMe() ->
    S = self(),
    Nodes = nodes(),
    %[spawn_node_worker(S, fun simplePrint/1, Node)||Node <- Nodes].
    [rpc:call(Node, ?MODULE, simplePrint ,["Hej"])||Node <- Nodes].


spawn_node_worker(Parent, Fun, Node)->
    spawn_link(Node, Fun(Parent)).

simplePrint(M) ->
    io:format('~p : message received', [M]).
