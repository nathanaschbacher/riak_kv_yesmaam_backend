% (The MIT License)

% Copyright (c) 2013 Nathan Aschbacher

% Permission is hereby granted, free of charge, to any person obtaining
% a copy of this software and associated documentation files (the
% 'Software'), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to
% permit persons to whom the Software is furnished to do so, subject to
% the following conditions:

% The above copyright notice and this permission notice shall be
% included in all copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-module(riak_kv_yesmaam_backend).
-behavior(riak_kv_backend).

%% KV Backend API
-export([api_version/0,
         capabilities/1,
         capabilities/2,
         start/2,
         stop/1,
         get/3,
         put/5,
         delete/4,
         drop/1,
         fold_buckets/4,
         fold_keys/4,
         fold_objects/4,
         is_empty/1,
         status/1,
         callback/3]).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-define(API_VERSION, 1).
-define(CAPABILITIES, [async_fold]).

-record(state, {static_obj}).
-type state() :: #state{}.
-type config() :: [{atom(), term()}].

%% ===================================================================
%% Public API
%% ===================================================================

%% @doc Return the major version of the
%% current API.
-spec api_version() -> {ok, integer()}.
api_version() ->
    {ok, ?API_VERSION}.

%% @doc Return the capabilities of the backend.
-spec capabilities(state()) -> {ok, [atom()]}.
capabilities(_) ->
    {ok, ?CAPABILITIES}.

%% @doc Return the capabilities of the backend.
-spec capabilities(riak_object:bucket(), state()) -> {ok, [atom()]}.
capabilities(_, _) ->
    {ok, ?CAPABILITIES}.

%% @doc Start this backend, yes, ma'am!
-spec start(integer(), config()) -> {ok, state()} | {error, term()}.
start(_Partition, _Config) ->
    Meta = dict:new(),
    Meta1 = dict:store(<<"X-Riak-Last-Modified">>, erlang:now(), Meta),
    Meta2 = dict:store(<<"X-Riak-VTag">>, make_vtag(erlang:now()), Meta1),

    Object = riak_object:increment_vclock(riak_object:new(<<"yesmaam!">>, <<"yesmaam!">>, <<"yesmaam!">>, Meta2), <<"yesmaam!">>, 1),
    
    {ok, #state{static_obj=term_to_binary(Object)}}.

%% @doc Stop this backend, yes, ma'am!
-spec stop(state()) -> ok.
stop(_State) ->
    ok.

%% @doc Get a fake object, yes, ma'am!
-spec get(riak_object:bucket(), riak_object:key(), state()) ->
                 {ok, any(), state()}.
get(_Bucket, _Key, #state{static_obj = Object} = State) ->
    {ok, Object, State}.

%% @doc Store an object, yes, ma'am!
-type index_spec() :: {add, Index, SecondaryKey} | {remove, Index, SecondaryKey}.
-spec put(riak_object:bucket(), riak_object:key(), [index_spec()], binary(), state()) ->
                 {ok, state()}.
put(_Bucket, _PKey, _IndexSpecs, _Val, State) ->
    {ok, State}.

%% @doc Delete an object, yes, ma'am!
-spec delete(riak_object:bucket(), riak_object:key(), [index_spec()], state()) ->
                    {ok, state()}.
delete(_Bucket, _Key, _IndexSpecs, State) ->
    {ok, State}.

%% @doc Fold over all the buckets, yes, ma'am!
-spec fold_buckets(riak_kv_backend:fold_buckets_fun(),
                   any(),
                   [],
                   state()) -> {ok, any()}.
fold_buckets(FoldBucketsFun, Acc, Opts, _State) ->
    BucketFolder =
        fun() ->
            FoldBucketsFun(<<"yesmaam!">>, Acc)
        end,
    case lists:member(async_fold, Opts) of
        true ->
            {async, BucketFolder};
        false ->
            {ok, BucketFolder()}
    end.

%% @doc Fold over all the keys for one or all buckets, yes, ma'am!
-spec fold_keys(riak_kv_backend:fold_keys_fun(),
                any(),
                [{atom(), term()}],
                state()) -> {ok, term()}.
fold_keys(FoldKeysFun, Acc, Opts, _State) ->
    KeyFolder =
        fun() ->
            FoldKeysFun(<<"yesmaam!">>, <<"yesmaam!">>, Acc)
        end,
    case lists:member(async_fold, Opts) of
        true ->
            {async, KeyFolder};
        false ->
            {ok, KeyFolder()}
    end.

%% @doc Fold over all the objects for one or all buckets, yes, ma'am!
-spec fold_objects(riak_kv_backend:fold_objects_fun(),
                   any(),
                   [{atom(), term()}],
                   state()) -> {ok, any()} | {async, fun()}.
fold_objects(FoldObjectsFun, Acc, Opts, #state{static_obj = Object} = _State) ->
    ObjectFolder =
        fun() ->
            FoldObjectsFun(<<"yesmaam!">>, <<"yesmaam!">>, Object, Acc)
        end,
    case lists:member(async_fold, Opts) of
        true ->
            {async, ObjectFolder};
        false ->
            {ok, ObjectFolder()}
    end.

%% @doc Delete all objects from this backend, yes, ma'am!
-spec drop(state()) -> {ok, state()}.
drop(State) ->
    {ok, State}.

%% @doc Returns true if this bitcasks backend contains any
%% non-tombstone values; otherwise returns false.
-spec is_empty(state()) -> false.
is_empty(_State) ->
    false.

-spec status(state()) -> [{atom(), term()}].
status(State) ->
    [State].

%% @doc Register an asynchronous callback
-spec callback(reference(), any(), state()) -> {ok, state()}.
callback(_Ref, _Whatever, State) ->
    {ok, State}.


%% borrowed from kv get_fsm...
make_vtag(Now) ->
    <<HashAsNum:128/integer>> = crypto:md5(term_to_binary({node(), Now})),
    riak_core_util:integer_to_list(HashAsNum,62).

%%
%% Test
%%
-ifdef(USE_BROKEN_TESTS).
-ifdef(TEST).
simple_test() ->
   Config = [],
   riak_kv_backend:standard_test(?MODULE, Config).

-ifdef(EQC).
eqc_test() ->
    Cleanup = fun(_State,_Olds) -> ok end,
    Config = [],
    ?assertEqual(true, backend_eqc:test(?MODULE, false, Config, Cleanup)).
-endif. % EQC
-endif. % TEST
-endif. % USE_BROKEN_TESTS
