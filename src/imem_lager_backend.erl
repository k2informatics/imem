-module(imem_lager_backend).
-behaviour(gen_event).
-include("imem_meta.hrl").

%% gen_event callbacks
-export([init/1,
         handle_event/2,
         handle_call/2,
         handle_info/2,
         terminate/2,
         code_change/3]).
-export([trace/1, trace/2]).
%% -export([test/0]).

-record(state, {
        tn_event,
        level = info,
        application,
        modules = [],
        table}).

%%%===================================================================
%%% trace
%%%===================================================================
trace(Filter) ->
    trace(Filter, debug).
trace(Filter, Level) ->
    Trace0 = {Filter, Level, ?MODULE},
    case lager_util:validate_trace(Trace0) of
        {ok, Trace} ->
            {MinLevel, Traces} = lager_config:get(loglevel),
            case lists:member(Trace, Traces) of
                false ->
                    lager_config:set(loglevel, {MinLevel, [Trace|Traces]});
                _ ->
                    ok
            end,
            {ok, Trace};
        Error ->
            Error
    end.

%%%===================================================================
%%% gen_event callbacks
%%%===================================================================
setup_table(Name, Fields, Types, Defaults) ->
    try
        imem_meta:init_create_check_table(
          Name, {Fields, Types, Defaults},
          [{record_name, element(1, Defaults)},
           {type, ordered_set}, {purge_delay,430000}],
          lager_imem),
        imem_meta:unsubscribe({table, ddConfig, simple}),
        imem_meta:subscribe({table, ddConfig, simple})
    catch
        _:Error -> throw(Error)
    end.

init(Params) ->
    State = state_from_params(#state{}, Params),
    setup_table(State#state.table,
                record_info(fields, ddLog),
                ?ddLog, #ddLog{}),
    {ok, State}.

handle_event({log, LagerMsg}, #state{table=DefaultTable, level = LogLevel} = State) ->
    case lager_util:is_loggable(LagerMsg, LogLevel, ?MODULE) of
        true ->
            Level = lager_msg:severity_as_int(LagerMsg),
            %{Date, Time} = lager_msg:timestamp(LagerMsg),
            Date = erlang:now(),
            Message = lager_msg:message(LagerMsg),
            Metadata = lager_msg:metadata(LagerMsg),
            Mod = proplists:get_value(module, Metadata),
            StackTrace = proplists:get_value(stacktrace, Metadata, []),
            case lists:member(Mod, State#state.modules) of
                true ->
                    Fun = proplists:get_value(function, Metadata),
                    Line = proplists:get_value(line, Metadata),

                    Pid = proplists:get_value(pid, Metadata),
                    Fields = [P || {K,_} = P <- Metadata, K /= node , K /= application,
                                   K /= module, K /= function, K /= line, K /= pid,
                                   K /= imem_table, K /= stacktrace],
                    
                    LogTable = proplists:get_value(imem_table, Metadata, DefaultTable),
                    LogRecord = if LogTable == DefaultTable -> ddLog;
                                   true -> LogTable
                                end,
                    
                    NPid = if is_list(Pid) -> list_to_pid(Pid); true -> Pid end,

                    EntryTuple = list_to_tuple(
                                   [LogRecord,
                                    Date,
                                    lager_util:num_to_level(Level),
                                    NPid,
                                    Mod,
                                    Fun,
                                    Line,
                                    node(),
                                    Fields,
                                    re:replace(Message, "((\\[.*\\])*([ ]*{[a-z0-9_]*,[0-9]*}))*[ ]*",
                                     "", [{return, binary}]),
                                    StackTrace
                                   ]),
                    try
                        imem_meta:dirty_write(LogTable, EntryTuple)
                    catch
                        _:Error ->
                            io:format(user, "[~p:~p] failed to write to ~p, ~p~n",
                                      [?MODULE, ?LINE, LogTable, Error])
                    end,
                    {ok, State};
                false ->
                    case State#state.modules of
                        [] ->
                            case application:get_key(State#state.application,modules) of
                                undefined ->    {ok, State};
                                {ok, Ms} ->     {ok, State#state{modules = Ms}}
                            end;
                        _ ->
                            %io:format(user, "[~p:~p] log skipped module ~p doesn't"
                            %                " belong to application ~p~n",
                            %                [?MODULE, ?LINE, Mod, State#state.application]),
                            {ok, State}
                    end
            end;
        false ->
            {ok, State}
    end;
handle_event({lager_imem_options, Params}, State) ->
    {ok, state_from_params(State, Params)};

handle_event(_Event, State) ->
    {ok, State}.

handle_call({set_loglevel, Level}, State) ->
    {ok, ok, State#state{level = lager_util:level_to_num(Level) }};

handle_call(get_loglevel, State = #state{level = Level}) ->
    {ok, Level, State}.

handle_info({mnesia_table_event, {write,{ddConfig,Match,DefaultTable,_,_},_}},
            #state{tn_event = Match, table=OldDefaultTable} = State) ->
    io:format(user, "Changing default table from ~p to ~p~n", [OldDefaultTable, DefaultTable]),
    {ok, State#state{table=DefaultTable}};
handle_info(_Info, State) ->
    %% we'll get (unused) log rotate messages
    {ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
state_from_params(OrigState = #state{level = OldLevel,
                                     application = OldApplication,
                                     tn_event = OldTableEvent}, Params) ->
    Table = case proplists:get_value(tablefun, Params) of
                TableFun when is_function(TableFun, 0) ->
                    TableFun();
                _ -> exit({badarg, missing_tablefun})
            end,
    Level = proplists:get_value(level, Params, OldLevel),
    TableEvent = proplists:get_value(tn_event, Params, OldTableEvent),
    Application = proplists:get_value(application, Params, OldApplication),
    Modules = case application:get_key(Application, modules) of
                  undefined -> OrigState#state.modules;
                  {ok, Mods} -> Mods
              end,
    OrigState#state{level=lager_util:level_to_num(Level),
                    table=Table,
                    tn_event = TableEvent,
                    application = Application,
                    modules = Modules}.
