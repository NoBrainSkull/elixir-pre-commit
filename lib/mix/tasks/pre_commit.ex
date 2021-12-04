defmodule Mix.Tasks.PreCommit do
  use Mix.Task
  require Logger

  @moduledoc """
    This file contains the functions that will be run when `mix pre_commit` is
    run. (we run it in the script in the `pre-commit` file in your `.git/hooks` directory but you can run it yourself if you want to see the output without committing).

    In here we just run all of the mix commands that you have put in your config file, and if they're succesful, print a success message to the
    the terminal, and if they fail we halt the process with a `1` error code (
    meaning that the command has failed), which will trigger the commit to stop,
    and print the error message to the terminal.
  """
  @commands Application.get_env(:pre_commit, :commands) || []
  @verbose Application.get_env(:pre_commit, :verbose) || false

  def run(_) do
    Logger.info("\e[95mPre-commit running...\e[0m")

    @commands
    |> Enum.each(&(
      case run_cmd(&1) do
        :error -> System.halt(1)
        _ -> :ok
      end
    ))

    Logger.info "\e[32mPre-commit passed!\e[0m"

    System.halt(0)
  end

  defp run_cmd(cmd) do
    into =
      case @verbose do
        true -> IO.stream(:stdio, :line)
        _ -> ""
      end

    System.cmd("mix", String.split(cmd, " "), stderr_to_stdout: true, into: into)
    |> case do
      {_result, 0} ->
        IO.puts("mix #{cmd} ran successfully.")
        :ok

      {result, _} ->
        if @verbose, do: Logger.info(result)

        Logger.error(
          "\e[31mPre-commit failed on `mix #{cmd}`.\e[0m \nCommit again with --no-verify to live dangerously and skip pre-commit."
        )

        :error
    end
  end
end
