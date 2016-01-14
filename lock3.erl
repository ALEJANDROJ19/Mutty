-module(lock3).
-export([start/1]).

%%MiId es un parametre que identifica un orden de prioridad respecto a un id
%%Reloj es un parametre que representa un rellotge lógic de Lamport

start(MiId) ->
    spawn(fun() -> init(MiId) end).

init(MiId) ->
    Reloj = 0,
    receive
        {peers, Nodes} ->
            open(Nodes,MiId,Reloj);
        stop ->
            ok
    end.

open(Nodes, MiId,Reloj) ->
    receive
        {take, Master} ->
            Refs = requests(Nodes, MiId,Reloj),
            wait(Nodes, Master, Refs, [], MiId, Reloj, Reloj);
        {request, From,  Ref, _, RelojRem} ->
            NReloj = lists:max([Reloj,RelojRem]) + 1,
            From ! {ok, Ref, NReloj},
            open(Nodes, MiId, NReloj);
        stop ->
            ok
    end.

requests(Nodes, MiId, Reloj) ->
    lists:map(
      fun(P) -> 
        R = make_ref(), 
        P ! {request, self(), R, MiId, Reloj}, 
        R 
      end, 
      Nodes).

wait(Nodes, Master, [], Waiting, MiId, Reloj, _) ->
    Master ! taken,
    held(Nodes, Waiting,MiId,Reloj);
    
wait(Nodes, Master, Refs, Waiting, MiId, Reloj, TimeStamp) ->
    receive
        {request, From, Ref, OtraId, RelojRem} ->
            NReloj = lists:max([Reloj,RelojRem]) + 1,
    	    if 
                RelojRem < TimeStamp ->
                    From ! {ok, Ref, NReloj}, 
                    wait(Nodes, Master, Refs, Waiting, MiId, NReloj, TimeStamp);  

                RelojRem == TimeStamp ->
                    if
                        OtraId < MiId ->
                  	        From ! {ok, Ref, NReloj},
                	        wait(Nodes, Master, Refs, Waiting, MiId, NReloj, TimeStamp);	      
            	        true -> 
                            wait(Nodes, Master, Refs, [{From, Ref}|Waiting], MiId, NReloj, TimeStamp)
                    end;
                true ->
                    wait(Nodes, Master, Refs, [{From, Ref}|Waiting], MiId, NReloj, TimeStamp)
    	    end;

        {ok, Ref, RelojRem} ->
            NReloj = lists:max([Reloj,RelojRem]) + 1,
            NewRefs = lists:delete(Ref, Refs),
            wait(Nodes, Master, NewRefs, Waiting, MiId, NReloj, TimeStamp);

        release ->
            ok(Waiting, Reloj),            
            open(Nodes, MiId, Reloj)
    end.

ok(Waiting, Reloj) ->
    lists:map(
      fun({F,R}) -> 
        F ! {ok, R, Reloj} 
      end, 
      Waiting).

held(Nodes, Waiting, MiId, Reloj) ->
    receive
        {request, From, Ref, _, RelojRem} ->
            NReloj = lists:max([Reloj,RelojRem]) + 1,
            held(Nodes, [{From, Ref}|Waiting],MiId, NReloj);
        release ->
            ok(Waiting, Reloj),
            open(Nodes,MiId, Reloj)
    end.