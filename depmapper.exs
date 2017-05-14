defmodule Mix.DepMapper do
  @repos_path "/home/at/code/erlang"

  @doc """
  Converts both Hex and Git dependencies to a Git dependency pointing to
  the desired branch in my set of audited git repos.
  """
  def mapdep(dep) do
    #IO.puts("dep: #{inspect dep, pretty: true, width: 0}")
    opts = Enum.into(dep.opts, %{})
    type = cond do
      Map.has_key?(opts, :hex) -> :hex
      Map.has_key?(opts, :git) -> :git
    end
    name = case type do
      :hex -> opts.hex
      :git -> opts.git |> String.split("/") |> List.last |> String.replace_suffix(".git", "") |> git_repo_name
      _    -> raise "Dependency is not of type hex or git:\n#{inspect dep, pretty: true, width: 0}"
    end
    git    = Path.join(@repos_path, name)
    branch = known_good_branch(name)
    if System.get_env("DEPMAPPER_DEBUG") do
      IO.puts("[depmapper] #{type} #{name} -> git #{git}:#{branch}")
    end
    opts = opts
      |> Map.delete(:hex)
      |> Map.put(:checkout, opts.dest)
      |> Map.put(:git,      git)
      |> Map.put(:branch,   branch)
    dep
    |> Map.put(:requirement, nil)
    |> Map.put(:scm,         Mix.SCM.Git)
    |> Map.put(:opts,        Enum.into(opts, []))
  end

  defp git_repo_name("erlang-certifi"),     do: "certifi"
  defp git_repo_name("erlang-idna"),        do: "idna"
  defp git_repo_name("erlang-metrics"),     do: "metrics"
  defp git_repo_name("ssl_verify_fun.erl"), do: "ssl_verify_fun"
  defp git_repo_name(other),                do: other

  # Return the branch to check out.  My workflow is to mark audited known-good
  # commits with both a branch and timestamped tag using
  # https://github.com/ludios/tagmyrebase
  #
  # For repositories whose upstream is ourselves, pick the master branch
  # so that we don't have to constantly mark it.
  defp known_good_branch(name) do
    cond do
      name in ["converge", "base_system", "debpress", "gears"] -> "master"
      String.starts_with?(name, "role_")                       -> "master"
      true                                                     -> "bien"
    end
  end
end
