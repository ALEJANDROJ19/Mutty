-module(lock2).
-export([start/1]).

%%MiId es un parametre que identifica un orden de prioridad respecto a un id

start(MiId) ->
    spawn(fun() -> init(MiId) end).

init(MiId) ->
    receive
        {peers, Nodes} ->
            open(Nodes, MiId);
        stop ->
            ok
    end.

open(Nodes, MiId) ->
    receive
        {take, Master} ->
            Refs = requests(Nodes, MiId),
            wait(Nodes, Master, Refs, [], MiId);
        {request, From,  Ref, _} ->
            From ! {ok, Ref},
            open(Nodes, MiId);
        stop ->
            ok
    end.

requests(Nodes, MiId) ->
    lists:map(
      fun(P) -> 
        R = make_ref(), 
        P ! {request, self(), R, MiId}, 
        R 
      end, 
      Nodes).

wait(Nodes, Master, [], Waiting, MiId) ->
    Master ! taken,
    held(Nodes, Waiting, MiId);
wait(Nodes, Master, Refs, Waiting, MiId) ->
    receive
        {request, From, Ref, OtraId} ->
            if 
                OtraId < MiId ->
                    From ! {ok, Ref},
                    NewRef = make_ref(),
                    From ! {request, self(), NewRef, MiId}, 
                    wait(Nodes, Master, [NewRef | Refs], Waiting, MiId);
                true -> 
                    wait(Nodes, Master, Refs, [{From, Ref}|Waiting], MiId)
            end;
        {ok, Ref} ->
            NewRefs = lists:delete(Ref, Refs),
            wait(Nodes, Master, NewRefs, Waiting, MiId);
        release ->
            ok(Waiting),            
            open(Nodes, MiId)
    end.

ok(Waiting) ->
    lists:map(
      fun({F,R}) -> 
        F ! {ok, R} 
      end, 
      Waiting).

held(Nodes, Waiting, MiId) ->
    receive
        {request, From, Ref, _} ->
            held(Nodes, [{From, Ref}|Waiting], MiId);
        release ->
            ok(Waiting),
            open(Nodes, MiId)
    end.