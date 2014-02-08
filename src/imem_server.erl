-module(imem_server).
-behaviour(ranch_protocol).

-include("imem.hrl").

-export([ start_link/4
        , start_link/1
        , stop/0
        , init/4
        , send_resp/2
        , mfa/2
        ]).
 
start_link(Params) ->
    Interface   = proplists:get_value(tcp_ip,Params),
    ListenPort  = proplists:get_value(tcp_port,Params),
    SSL         = proplists:get_value(ssl,Params),
    {THandler, Opts} = if length(SSL) > 0 -> {ranch_ssl, SSL}; true -> {ranch_tcp, []} end, 
    case inet:getaddr(Interface, inet) of
        {error, Reason} ->
            ?Error("~p [ERROR] not started ~p~n", [self(), Reason]),
            {error, Reason};
        {ok, ListenIf} when is_integer(ListenPort) ->
            ?Info("~p listening on ~p:~p ~s~n", [self(), ListenIf, ListenPort, if THandler =:= ranch_ssl -> "(ssl)"; true -> "" end]),
            ranch:start_listener(?MODULE, 1, THandler, [{ip, ListenIf}, {port, ListenPort} | Opts], ?MODULE, if THandler =:= ranch_ssl -> [ssl]; true -> [] end);
        _ ->
            {stop, disabled}
    end.

start_link(ListenerPid, Socket, Transport, Opts) ->
    Pid = spawn_opt(?MODULE, init, [ListenerPid, Socket, Transport, Opts], [link, {fullsweep_after, 0}]),
    {ok, Pid}.

stop() ->
    ranch:stop_listener(?MODULE).
 
init(ListenerPid, Socket, Transport, Opts) ->
    PeerNameMod = case lists:member(ssl, Opts) of true -> ssl; _ -> inet end,
    {ok, {Address, Port}} = PeerNameMod:peername(Socket),
    Str = lists:flatten(io_lib:format("~p received connection from ~p:~p", [self(), Address, Port])),
    ?Log(Str++"~n", []),
    imem_meta:log_to_db(info,?MODULE,init,[ListenerPid, Socket, Transport, Opts], Str),
    ok = ranch:accept_ack(ListenerPid),
    loop(Socket, Transport, <<>>, 0).

-define(TDebug(__F, __A), ok). 
%-define(TDebug(__F, __A), ?Debug(__F, __A)). 
loop(Socket, Transport, Buf, Len) ->
    {OK, Closed, Error} = Transport:messages(),
    Transport:setopts(Socket, [{active, once}]),   
    receive
        {OK, Socket, Data} ->
            {NewLen, NewBuf} =
                if Buf =:= <<>> ->
                    << L:32, PayLoad/binary >> = Data,
                    ?TDebug(" term size ~p~n", [<< L:32 >>]),
                    {L, PayLoad};
                true -> {Len, <<Buf/binary, Data/binary>>}
            end,
            case {byte_size(NewBuf), NewLen} of
                {NewLen, NewLen} ->
                    case (catch binary_to_term(NewBuf)) of
                        {'EXIT', _} ->
                            ?Info(" [MALFORMED] ~p received ~p bytes buffering...", [self(), byte_size(NewBuf)]),
                            loop(Socket, Transport, NewBuf, NewLen);
                        Term ->
                            if element(2, Term) =:= imem_sec ->
                                mfa(Term, {Transport, Socket, element(1, Term)});
                            true ->
                                send_resp({error, {"security breach attempt", Term}}, {Transport, Socket, element(1, Term)})
                            end,
                            TSize = byte_size(term_to_binary(Term)),
                            RestSize = byte_size(NewBuf)-TSize,
                            loop(Socket, Transport, binary_part(NewBuf, {TSize, RestSize}), NewLen)
                    end;
                _ ->
                    ?Info(" [INCOMPLETE] ~p received ~p bytes buffering...", [self(), byte_size(NewBuf)]),
                    loop(Socket, Transport, NewBuf, NewLen)
            end;
        {Closed, Socket} ->
            ?Debug("socket ~p got closed!~n", [Socket]);
        {Error, Socket, Reason} ->
            ?Error("socket ~p error: ~p", [Socket, Reason]);
        close ->
            ?Warn("closing socket...~n", [Socket]),
            Transport:close(Socket)
    end.

mfa({Ref, Mod, which_applications, Args}, Transport) when Mod =:= imem_sec;
                                                          Mod =:= imem_meta ->
    mfa({Ref, application, which_applications, Args}, Transport);
mfa({Ref, Mod, Fun, Args}, Transport) ->
    NewArgs = args(Ref,Fun,Args,Transport),
    ApplyRes = try
                   ?TDebug("~p MFA -> R ~n ~p:~p(~p)~n", [Transport,Mod,Fun,NewArgs]),
                   apply(Mod,Fun,NewArgs)
               catch 
                    _Class:Reason -> {error, {Reason, erlang:get_stacktrace()}}
               end,
    ?TDebug("~p MFA -> R ~n ~p:~p(~p) -> ~p~n", [Transport,Mod,Fun,NewArgs,ApplyRes]),
    ?TDebug("~p MF -> R ~n ~p:~p -> ~p~n", [Transport,Mod,Fun,ApplyRes]),
    send_resp(ApplyRes, Transport),
    ok. % 'ok' returned for erlimem compatibility

args(R, fetch_recs_async, A, {_,_,R} = T) ->
    Args = lists:sublist(A, length(A)-1) ++ [T],
    ?TDebug("fetch_recs_async, Args for TCP~n ~p~n", [Args]),
    Args;
args(R, fetch_recs_async, A, {_,R} = T) ->
    Args = lists:sublist(A, length(A)-1) ++ [T],
    ?TDebug("fetch_recs_async, Args for direct~n ~p~n", [Args]),
    Args;
args(_, _F, A, _) ->
    ?TDebug("~p(~p)~n", [_F, A]),
    A.

send_resp(Resp, {Transport, Socket, Ref}) ->
    RespBin = term_to_binary({Ref, Resp}),
    ?TDebug("TX (~p)~n~p~n", [byte_size(RespBin), RespBin]),
    PayloadSize = byte_size(RespBin),
    Transport:send(Socket, << PayloadSize:32, RespBin/binary >>);
send_resp(Resp, {Pid, Ref}) when is_pid(Pid) ->
    Pid ! {Ref, Resp}.
