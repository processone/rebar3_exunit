A rebar3 plugin to enable the execution of Elixir ExUnit test. 

# Usage

Make sure your package list from Hex.pm is up-to-date:

    rebar3 update

Add `rebar3_exunit` in your plugin list, in your `rebar.config` file:

    {plugins, [rebar3_exunit]}.

Download plugin and run your Elixit ExUnit tests in the test directory
with the rebar command:

    rebar3 exunit

