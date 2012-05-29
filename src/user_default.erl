-module(user_default).

%% Interface exports
-export([help/0]).

-export([p/1, p/2]).
-export([pe/1, pe/2]).
-export([yy/1, yp/1]).
-export([reload/0]).

-export([debug/1]).
-export([debug/2]).
-export([debug/3]).
-export([debug_on/0]).
-export([debug_off/0]).
-export([debug_off/1]).
-export([debug_off/2]).
-export([debug_options/0]).

%% +-----------------------------------------------------------------+
%% | OUTPUT SHORTCUTS                                                |
%% +-----------------------------------------------------------------+
p(String)        -> io:format(String).
p(String, Args)  -> io:format(String, Args).
pe(String)       -> p(lists:append(String, "~n")).
pe(String, Args) -> p(lists:append(String, "~n"), Args).
yy(Term)         -> pe("~w", [Term]).
yp(Term)         -> pe("~p", [Term]).
reload()         -> sync:go().

%% +-----------------------------------------------------------------+
%% | NESTED TRACER                                                   |
%% +-----------------------------------------------------------------+
nested({trace, _Pid, call, {Mod, Fun, Params}}, Level) ->
    NewParams = format_params(Params),
    io:format("~s~p:~p~s\n", [fill_spaces(Level), Mod, Fun, NewParams]),
    Level + 1;
nested({trace, _Pid, return_from, {_, _, _}, ReturnValue}, Level) ->
    NewLevel = Level - 1,
    io:format("~s~p\n", [fill_spaces(NewLevel), ReturnValue]),
    NewLevel;
nested(Any, Level) ->
    io:format("trace_msg: ~p\n", [Any]),
    Level.

nested_tracer() ->
    dbg:tracer(process, {fun nested/2, 0}).

fill_spaces(Level) ->
    lists:duplicate(Level, "| ").

format_params(Params) ->
    Params1 = io_lib:format("~p", [Params]),
    Opts = [global, {return, list}],
    Params2 = re:replace(Params1, "^\\[", "(", Opts),
    Params3 = re:replace(Params2, "\\]$", ")", Opts),
    re:replace(Params3, "\\,", ", ", Opts).

%% +-----------------------------------------------------------------+
%% | DEBUG FUNCTIONS                                                 |
%% +-----------------------------------------------------------------+

debug_on() ->
    {ok, _} = nested_tracer(),
    {ok, _} = dbg:p(all, call),
    ok.

debug(Module)
  when is_atom(Module) ->
    debug(Module, user_defualt:debug_options()).

debug(Module, DebugOptions)
  when is_atom(Module),
       is_list(DebugOptions) ->
    {ok, _} = dbg:tpl(Module, DebugOptions),
    ok;
debug(Module, Function)
  when is_atom(Module),
       is_atom(Function) ->
    debug(Module, Function, user_default:debug_options()).
debug(Module, Function, DebugOptions)
  when is_atom(Module),
       is_atom(Function) ->
    {ok, _} = dbg:tpl(Module, Function, DebugOptions),
    ok.

debug_off() ->
    dbg:stop(),
    ok.
debug_off(Module)
  when is_atom(Module) ->
    dbg:ctpl(Module),
    ok.
debug_off(Module, Function)
  when is_atom(Module),
       is_atom(Function) ->
    dbg:ctpl(Module, Function),
    ok.

debug_options() ->
    [{'_', [], [{return_trace}, {exception_trace}]}].

%% +-----------------------------------------------------------------+
%% | HELP MENU                                                       |
%% +-----------------------------------------------------------------+

help() ->
    shell_default:help(),
    pe(""),
    pe("** custom commands:"),
    pe("reload()         -- run code reloader"),
    pe("p(String)        -- print string"),
    pe("p(String, Args)  -- print string with format"),
    pe("pe(String)       -- print string with ~n"),
    pe("pe(String, Args) -- print string with format and ~n"),
    pe("yy(Term)         -- print raw term"),
    pe("yp(Term)         -- print term").
