%%%========================================================================
%%% File: ring.erl
%%%
%%% This module implements a simple ring benchmark in Erlang.
%%%
%%%
%%% The ring benchmark is about sending a message over a ring of processes.
%%% The following are the parameters of the benchmark that can be
%%% configured:
%%%
%%%   - Number of processes `P`
%%%   - Size of the message (in bytes)
%%%   - Type of the message (string or binary)
%%%   - Number of times the message is circulated over the ring `N`
%%%
%%% Once the benchmark has finished, a total of `P` * `N`
%%% messages will have been sent.
%%%
%%% Note that ERTS does not allow you to create more than 262144 processes.
%%% This number can be changed by starting the Erlang emulator using the
%%% +P flag (i.e. erl +P 500000).
%%%
%%%
%%% Author: Enrique Fernandez <efcasado@gmail.com>
%%%
%%%-- LICENSE -------------------------------------------------------------
%%% The MIT License (MIT)
%%%
%%% Copyright (c) 2015 Enrique Fernandez
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining
%%% a copy of this software and associated documentation files (the
%%% "Software"), to deal in the Software without restriction, including
%%% without limitation the rights to use, copy, modify, merge, publish,
%%% distribute, sublicense, and/or sell copies of the Software,
%%% and to permit persons to whom the Software is furnished to do so,
%%% subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included
%%% in all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
%%% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
%%% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
%%% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
%%% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
%%% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%========================================================================
-module(ring).

%% API
-export([run/4]).


%%=========================================================================
%% API
%%=========================================================================

%%-------------------------------------------------------------------------
%% @doc
%% Run the ring benchmark using `P` processes and circulating the message
%% over the ring `N` times. That is, a total of `N` * `P` messages will
%% be sent. The circulated message is of size `Size` and can be either a
%% string or a binary.
%% @end
%%-------------------------------------------------------------------------
run(P, Size, Type, N) when P > 0, N > 0 ->
    Peer1 = spawn(fun() -> loop0() end),
    PeerP = lists:foldl(fun(_, Peer) -> spawn(fun() -> loop(Peer) end) end,
                        Peer1,
                        lists:seq(2, P)),
    Msg = gen_msg(Size, Type),
    Peer1 ! {init, self(), PeerP, Msg, N},
    receive
        {result, Result} ->
            Result
    end.

%%=========================================================================
%% Local functions
%%=========================================================================

loop0() ->
    receive
        {init, Orig, Peer, Msg, N} ->
            T0 = erlang:now(),
            Peer ! {msg, Orig, self(), N, T0, T0, {0, 0}, Msg},
            loop(Peer)
    end.

loop(Peer) ->
    receive
        {msg, Pid1, Pid2, Cnt, T0, T1, {Acc, N}, _Msg}
          when Pid2 == self(), Cnt == 1 ->
            T2 = erlang:now(),
            Lat = timer:now_diff(T2, T1),
            AvgLat = (Acc + Lat) / (N + 1),
            TotTime = timer:now_diff(T2, T0),
            Peer ! stop,
            Pid1 ! {result, {AvgLat, TotTime}};
        {msg, Pid1, Pid2, Cnt, T0, T1, {Acc, N}, Msg} when Pid2 == self() ->
            T2 = erlang:now(),
            Lat = timer:now_diff(T2, T1),
            Peer ! {msg, Pid1, Pid2, Cnt - 1, T0, T2, {Acc + Lat, N + 1}, Msg},
            loop(Peer);
        {msg, Pid1, Pid2, Cnt, T0, T1, {Acc, N}, Msg} ->
            T2 = erlang:now(),
            Lat = timer:now_diff(T2, T1),
            Peer ! {msg, Pid1, Pid2, Cnt, T0, T2, {Acc + Lat, N + 1}, Msg},
            loop(Peer);
        stop ->
            Peer ! stop
    end.

gen_msg(Size, bin) ->
    list_to_binary(gen_msg(Size, str));
gen_msg(Size, str) ->
    lists:foldl(fun(_, Msg) -> [random:uniform(94) + 32| Msg] end,
                [],
                lists:seq(1, Size)).
