%%%-------------------------------------------------------------------
%%% File        : imem_SUITE.erl
%%% Description : Common testing imem.
%%%
%%% Created     : 20.11.2017
%%%
%%% Copyright (C) 2017 K2 Informatics GmbH
%%%-------------------------------------------------------------------

-module(imem_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([
    all/0,
    end_per_group/2,
    end_per_suite/1,
    groups/0,
    init_per_group/2,
    init_per_suite/1,
    suite/0
]).

-export([
    cache_test_without_sec/1,
    config_operations/1,
    dal_skvh_concurrency/1,
    dal_skvh_operations/1,
    if_csv_test_csv_1/1,
    if_mnesia_table_operations/1,
    meta_concurrency/1,
    meta_operations/1,
    meta_partitions/1,
    meta_preparations/1
]).

%%--------------------------------------------------------------------
%% Returns the list of all test cases and test case groups
%% in the test suite module to be executed.
%%--------------------------------------------------------------------

all() ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":all/0 - Start ===>~n", []),
    [
        {group, imem_cache},
        {group, imem_config},
        {group, imem_dal_skvh},
        {group, imem_if_csv},
        {group, imem_if_mnesia},
        {group, imem_meta}
    ].

%%--------------------------------------------------------------------
% The test suite information function.
%%--------------------------------------------------------------------

suite() ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":suite/0 - Start ===>~n", []),
    [
        {timetrap, {minutes, 10}}
    ].

%%--------------------------------------------------------------------
%% Suite related setup and teardown functions.
%%--------------------------------------------------------------------

init_per_suite(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":init_per_suite/1 - Start ===>~n", []),
    application:load(imem),
    application:set_env(imem, mnesia_node_type, disc),
    imem:start(),
    Config.

end_per_suite(_Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":end_per_suite/1 - Start ===>~n", []),
    imem:stop(),
    ok.

%%--------------------------------------------------------------------
% Defines test case groups.
%%--------------------------------------------------------------------

groups() ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":groups/0 - Start ===>~n", []),
    [
        {
            imem_cache, [],
            [
                cache_test_without_sec
            ]
        },
        {
            imem_config, [],
            [
                config_operations
            ]
        },
        {
            imem_dal_skvh, [],
            [
                dal_skvh_concurrency,
                dal_skvh_operations
            ]
        },
        {
            imem_if_csv, [],
            [
                if_csv_test_csv_1
            ]
        },
        {
            imem_if_mnesia, [],
            [
                if_mnesia_table_operations
            ]
        },
        {
            imem_meta, [],
            [
                meta_operations,
                meta_preparations,
                meta_partitions,
                meta_concurrency
            ]
        }
    ].

%%--------------------------------------------------------------------
%% Group related setup and teardown functions.
%%--------------------------------------------------------------------

init_per_group(imem_dal_skvh = Group, Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":init_per_group/2 - ~p - Start ===>~n", [Group]),
    imem_dal_skvh_ct:init_per_group(Config);
init_per_group(_Group, Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":init_per_group/2 - ~p - Start ===>~n", [_Group]),
    Config.

end_per_group(imem_config = Group, Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":end_per_group/2 - ~p - Start ===>~n", [Group]),
    imem_config:end_per_group(Config);
end_per_group(imem_dal_skvh = Group, Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":end_per_group/2 - ~p - Start ===>~n", [Group]),
    imem_dal_skvh_ct:end_per_group(Config);
end_per_group(imem_if_mnesia = Group, Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":end_per_group/2 - ~p - Start ===>~n", [Group]),
    imem_if_mnesia_ct:end_per_group(Config);
end_per_group(imem_meta = Group, Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":end_per_group/2 - ~p - Start ===>~n", [Group]),
    imem_meta_ct:end_per_group(Config);
end_per_group(_Group, _Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":end_per_group/2 - ~p - Start ===>~n", [_Group]),
    ok.

%%====================================================================
%% Test Cases: imem_config.
%%====================================================================

config_operations(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":config_operations/1 - Start ===>~n", []),
    imem_config_ct:config_operations(Config).

%%====================================================================
%% Test Cases: imem_cache.
%%====================================================================

cache_test_without_sec(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":cache_test_without_sec/1 - Start ===>~n", []),
    imem_cache_ct:test_without_sec(Config).

%%====================================================================
%% Test Cases: imem_dal_skvh.
%%====================================================================

dal_skvh_concurrency(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":dal_skvh_concurrency/1 - Start ===>~n", []),
    imem_dal_skvh_ct:skvh_concurrency(Config).

dal_skvh_operations(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":dal_skvh_operations/1 - Start ===>~n", []),
    imem_dal_skvh_ct:skvh_operations(Config).

%%====================================================================
%% Test Cases: imem_if_csv.
%%====================================================================

if_csv_test_csv_1(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":config_operations/1 - Start ===>~n", []),
    imem_if_csv_ct:test_csv_1(Config).

%%====================================================================
%% Test Cases: imem_if_mnesia.
%%====================================================================

if_mnesia_table_operations(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":config_operations/1 - Start ===>~n", []),
    imem_if_mnesia_ct:table_operations(Config).

%%====================================================================
%% Test Cases: imem_meta.
%%====================================================================

meta_concurrency(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":meta_concurrency/1 - Start ===>~n", []),
    imem_meta_ct:meta_concurrency(Config).

meta_operations(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":meta_operations/1 - Start ===>~n", []),
    imem_meta_ct:meta_operations(Config).

meta_partitions(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":meta_partitions/1 - Start ===>~n", []),
    imem_meta_ct:meta_partitions(Config).

meta_preparations(Config) ->
    ct:pal(info, ?MAX_IMPORTANCE, ?MODULE_STRING ++ ":meta_preparations/1 - Start ===>~n", []),
    imem_meta_ct:meta_preparations(Config).
