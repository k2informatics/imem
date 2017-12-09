%%%-------------------------------------------------------------------
%%% File        : imem_cache_ct.erl
%%% Description : Common testing imem_cache.
%%%
%%% Created     : 09.12.2017
%%%
%%% Copyright (C) 2017 K2 Informatics GmbH
%%%-------------------------------------------------------------------

-module(imem_cache_ct).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-export([
    test_without_sec/1
]).

-define(NODEBUG, true).

-include_lib("imem.hrl").

%%====================================================================
%% Test Cases.
%%====================================================================

test_without_sec(_Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":test_without_sec/1 - Start ===>~n", []),
    try
        ?LogDebug("---TEST---"),

        % ?LogDebug("schema ~p~n", [imem_meta:schema()]),
        % ?LogDebug("data nodes ~p~n", [imem_meta:data_nodes()]),
        ?assertEqual(true, is_atom(imem_meta:schema())),
        ?assertEqual(true, lists:member({imem_meta:schema(), node()}, imem_meta:data_nodes())),

        % ?LogDebug("~p:test_mnesia~n", [?MODULE]),

        ?assertEqual(true, is_atom(imem_meta:schema())),
        % ?LogDebug("success ~p~n", [schema]),
        ?assertEqual(true, lists:member({imem_meta:schema(), node()}, imem_meta:data_nodes())),
        % ?LogDebug("success ~p~n", [data_nodes]),

        % ?LogDebug("~p:cache_operations~n", [?MODULE]),

        ?assertEqual([], imem_cache:read(some_test_key)),
        ?assertEqual(ok, imem_cache:write(some_test_key, "Test Value")),
        ?assertEqual(["Test Value"], imem_cache:read(some_test_key)),
        ?assertEqual(ok, imem_cache:clear_local(some_test_key)),
        ?assertEqual([], imem_cache:read(some_test_key)),

        % ?LogDebug("success ~p~n", [cache_operations]),
        ok

    catch
        Class:Reason ->
            ?LogDebug("Exception ~p:~p~n~p~n", [Class, Reason, erlang:get_stacktrace()]),
            ?assert(true == "all tests completed")
    end,
    ok.
