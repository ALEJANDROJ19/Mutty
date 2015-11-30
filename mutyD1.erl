-module(mutyD1).
-export([start/3, stop/0]).


start(Lock, Sleep, Work) ->
    register(l1, apply(Lock, start, [1])),

    l1 ! {peers, [{l2, 'n2@127.0.0.1'}, {l3, 'n3@127.0.0.1'}, {l4, 'n4@127.0.0.1'}]},

    register(w1, worker:start("John", l1, Sleep, Work)),
    ok.

stop() ->
    w1 ! stop.