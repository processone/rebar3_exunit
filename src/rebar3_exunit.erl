%% @doc
%% Add the plugin to your rebar config:
%%
%% ```
%% {plugins, [rebar3_exunit]}.'''
%%
%% Then just call your plugin directly in an existing application to run
%% ExUnit tests (.exs files) from the test/ directory.
%%
%% ```
%% $ rebar3 exunit
%% ===> Fetching rebar3_exunit_plugin
%% ===> Compiling rebar3_exunit_plugin'''

-module(rebar3_exunit).

-behaviour(provider).

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, exunit).
-define(DEPS, [compile]).
-define(DEFAULT_TEST_DIR, "test").

%%%===================================================================
%%% API
%%%===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([{name, ?PROVIDER},
                                 {module, ?MODULE},
                                 {deps, ?DEPS},
                                 {bare, true},
                                 {example, "rebar3 exunit"},
                                 {short_desc, "Run ExUnit tests."},
                                 {desc, ""},
                                 {opts, exunit_opts(State)},
                                 {profiles, [test]}]),
    State1 = rebar_state:add_provider(State, Provider),
    State2 = rebar_state:add_to_profile(State1, test, []),
    elixir_dep_code_path(State2),
    {ok, State2}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    rebar_api:info("Performing ExUnit tests...", []),
    rebar_utils:update_code(rebar_state:code_paths(State, all_deps)),

    %% Run exunit provider prehooks
    Providers = rebar_state:providers(State),
    Cwd = rebar_dir:get_cwd(),
    rebar_hooks:run_all_hooks(Cwd, pre, ?PROVIDER, Providers, State),

    {ok, Tests} = prepare_tests(State),
    case do_tests(State, Tests) of
        ok ->
            rebar_utils:cleanup_code_path(rebar_state:code_paths(State, default)),
            {ok, State};
        error ->
            rebar_utils:cleanup_code_path(rebar_state:code_paths(State, default)),
            rebar_api:error("Some ExUnit tests failed", []),
            {ok, State}
    end.

do_tests(_State, ElixirTests) ->
    %% Run elixir tests
    lists:foldl(
      fun(TestFile, Acc) ->
              case run_elixir_test(TestFile) of
                  {ok, 0} ->
                      Acc;
                  {ok, _N} ->
                      rebar_api:error("  Tests failed on ~s", [TestFile]),
                      error
              end
      end, ok, ElixirTests).

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%%%===================================================================
%%% Internal Functions
%%%===================================================================

%% Add Elixir lib subdirs from dependencies in code path
elixir_dep_code_path(State) ->
    PluginDir = rebar_dir:plugins_dir(State),
    PluginSubEbinDirs = filelib:wildcard(filename:join(PluginDir, "*/lib/*/ebin")),
    rebar_utils:update_code(PluginSubEbinDirs).

prepare_tests(State) ->
    {RawOpts, _} = rebar_state:command_parsed_args(State),
    resolve_tests(RawOpts).

resolve_tests(RawOpts) ->
    case proplists:get_value(file, RawOpts) of
        undefined -> resolve_all(RawOpts);
        Files     -> resolve_files(Files, RawOpts)
    end.

resolve_all(_Opts) ->
    Files = filelib:fold_files(test_dir(), ".*\.exs", false,
                       fun(Filename, Acc) ->
                               [filename:basename(Filename) | Acc] end, []),
    {ok, Files}.

resolve_files(Files, _Opts) ->
    FileNames = string:tokens(Files, [$,]),
    {ok, set_files(FileNames, [])}.

%% TODO I need to
%% - Add "test" path prefix if there is only a file name
%% - Check if the file exist and display a proper error message if the file does not exist
set_files([], Acc) -> lists:reverse(Acc);
set_files([File|Rest], Acc) ->
    FileWithExt = case filename:extension(File) of
                      [] -> File ++ ".exs";
                      ".exs" ->
                          File
                  end,
    set_files(Rest, [FileWithExt|Acc]).

run_elixir_test(Module) ->
    rebar_api:info("  Starting tests in ~s", [Module]),
    'Elixir.ExUnit':start([]),
    'Elixir.Code':load_file(list_to_binary(filename:join(test_dir(), Module))),
    %% I did not use map syntax, so that this file can still be build under R16
    ResultMap = 'Elixir.ExUnit':run(),
    maps:find(failures, ResultMap).

%% TODO: Make ExUnit test dir name an option
test_dir() ->
    ?DEFAULT_TEST_DIR.
        
exunit_opts(_State) ->
    [{file, $f, "file", string, help(file)}].

help(file)    -> "Comma separated list of files to run.".

%%%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
