-module(mutyD3).
-export([start/3, stop/0]).


start(Lock, Sleep, Work) ->
    register(l3, apply(Lock, start, [3])),

    l3 ! {peers, [{l1, 'n1@127.0.0.1'}, {l2, 'n2@127.0.0.1'}, {l4, 'n4@127.0.0.1'}]},

    register(w3, worker:start("Paul", l3, Sleep, Work)),
    ok.

stop() ->
    w3 ! stop.