defmodule Mix.Tasks.Meadow.Ldap do
  @moduledoc """
  Base module for LDAP tasks
  """

  defmodule Setup do
    @moduledoc """
    Add LDAP entries specified in LDIF file(s)
    """
    use Mix.Task
    alias Mix.Tasks.Meadow.Ldap.Common
    require Logger

    @shortdoc @moduledoc
    def run(seed_files) do
      unless length(seed_files) != 0 do
        Mix.raise("Error: No seed file specified.")
      end

      seed_files
      |> Enum.each(fn seed_file ->
        Logger.info("Seeding #{Path.basename(seed_file)}")
        Common.run(seed_file)
      end)
    end
  end

  defmodule Teardown do
    @moduledoc """
    Delete LDAP entries specified in LDIF file(s)
    """
    use Mix.Task
    alias Mix.Tasks.Meadow.Ldap.Common
    require Logger

    @shortdoc @moduledoc
    def run(seed_files) do
      unless length(seed_files) != 0 do
        Mix.raise("Error: No seed file specified.")
      end

      seed_files |> Enum.each(&unseed/1)
    end

    defp unseed(seed_file) do
      Logger.info("Reaping #{Path.basename(seed_file)}")

      with ldif <- File.read!(seed_file),
           {mega, sec, micro} <- :os.timestamp(),
           tempfile <- System.tmp_dir!() |> Path.join("#{mega}#{sec}#{micro}.ldif") do
        ldif =
          Regex.replace(~r"\n +", ldif, "")
          |> String.split(~r"\n")
          |> Enum.filter(&String.starts_with?(&1, "dn:"))
          |> Enum.reverse()
          |> Enum.map_join("\n", &"#{&1}\nchangetype: delete\n")

        File.write!(tempfile, ldif)
        Common.run(tempfile)
        File.rm!(tempfile)
      end
    end
  end

  defmodule Common do
    @moduledoc """
    Common functions for Setup/Teardown tasks
    """
    @executable "ldapmodify"

    require Logger

    def run(ldif_file) do
      unless File.exists?(ldif_file) do
        Logger.warn("ldif file #{ldif_file} not found.")
      end

      with args <- ldap_args() ++ ["-f", ldif_file] do
        case System.find_executable(@executable) do
          nil -> Logger.error("COMMAND NOT FOUND: #{@executable}")
          cmd -> System.cmd(cmd, args, stderr_to_stdout: true)
        end
      end
    end

    defp ldap_args do
      with config <- Application.get_env(:exldap, :settings),
           protocol <- if(config[:ssl], do: "ldaps", else: "ldap") do
        [
          "-H",
          "#{protocol}://#{config[:server]}:#{config[:port]}",
          "-D",
          config[:user_dn],
          "-w",
          config[:password],
          "-c"
        ]
      end
    end
  end
end
