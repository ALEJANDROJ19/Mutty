-module(mutyD2).
-export([start/3, stop/0]).


start(Lock, Sleep, Work) ->
    register(l2, apply(Lock, start, [2])),

    l2 ! {peers, [{l1, 'n1@127.0.0.1'}, {l3, 'n3@127.0.0.1'}, {l4, 'n4@127.0.0.1'}]},

    register(w2, worker:start("Ringo", l2, Sleep, Work)),
    ok.

stop() ->
    w2 ! stop.