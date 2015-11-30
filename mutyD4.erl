-module(mutyD4).
-export([start/3, stop/0]).


start(Lock, Sleep, Work) ->
    register(l4, apply(Lock, start, [4])),

    l4 ! {peers, [{l1, 'n1@127.0.0.1'}, {l2, 'n2@127.0.0.1'}, {l3, 'n3@127.0.0.1'}]},

    register(w4, worker:start("George", l4, Sleep, Work)),
    ok.

stop() ->
    w4 ! stop.