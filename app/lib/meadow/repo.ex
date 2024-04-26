defmodule Meadow.Repo do
  use Ecto.Repo,
    otp_app: :meadow,
    adapter: Ecto.Adapters.Postgres

  alias Meadow.Utils.Logging

  require Logger
  require Logging
  require WaitForIt

  @doc """
  Credit to Saša Jurić https://github.com/sasa1977/mix_phx_alt/blob/8ef7c36e5ac1a13a8152d0991757811cfd479568/lib/core/repo.ex#L6
  Runs the given function inside a transaction.

  This function is a wrapper around `Ecto.Repo.transaction`, with the following differences:

  - It accepts only a lambda of arity 0 or 1 (i.e. it doesn't work with multi).
  - If the lambda returns `:ok | {:ok, result}` the transaction is committed.
  - If the lambda returns `:error | {:error, reason}` the transaction is rolled back.
  - If the lambda returns any other kind of result, an exception is raised, and the transaction is rolled back.
  - The result of `transact` is the value returned by the lambda.

  This function accepts the same options as `Ecto.Repo.transaction/2`.
  """
  @spec transact((-> result) | (module -> result), Keyword.t()) :: result
        when result: :ok | {:ok, any} | :error | {:error, any}
  def transact(fun, opts \\ []) do
    transaction_result =
      transaction(
        fn repo ->
          lambda_result =
            case Function.info(fun, :arity) do
              {:arity, 0} -> fun.()
              {:arity, 1} -> fun.(repo)
            end

          case lambda_result do
            :ok -> {__MODULE__, :transact, :ok}
            :error -> rollback({__MODULE__, :transact, :error})
            {:ok, result} -> result
            {:error, reason} -> rollback(reason)
          end
        end,
        opts
      )

    with {outcome, {__MODULE__, :transact, outcome}}
         when outcome in [:ok, :error] <- transaction_result,
         do: outcome
  end

  def init(_, opts), do: {:ok, opts}

  def listen(event_name) do
    notification_listener_pid()
    |> Postgrex.Notifications.listen(event_name)
  end

  defp notification_listener_pid do
    case Process.whereis(Meadow.Postgrex.Notifications) do
      nil -> start_notification_listener()
      pid -> pid
    end
  end

  defp start_notification_listener do
    with {:ok, pid} <-
           __MODULE__.config()
           |> Keyword.put_new(:name, Meadow.Postgrex.Notifications)
           |> Postgrex.Notifications.start_link() do
      pid
    end
  end

  def wait_for_connection do
    Logger.info("Waiting for active database connection...")
    canary() |> WaitForIt.wait(timeout: 60_000, frequency: 1_000)
  end

  defp canary do
    Logging.with_log_level :info do
      case __MODULE__.query("SELECT 1") do
        {:ok, %{rows: [[1]]}} -> :ok
        _ -> :error
      end
    end
  rescue
    _ in DBConnection.ConnectionError -> :error
  end
end
