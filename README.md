A rebar3 plugin to enable the execution of Elixir ExUnit test. 

# Usage

Add `rebar3_exunit` in your plugin list, in your `rebar.config` file:

    {plugins, [rebar3_hex, {rebar3_exunit, {git, "git@github.com:processone/rebar3_exunit.git"}}

Note: you cannot use the `hex.pm` package name, as rebar3_exunit download Elixir as a dependency
and Elixir is not a packaged dependency on `hex.pm`.

Download plugin and run your Elixit ExUnit tests in the test directory
with the rebar command:

    rebar3 exunit
