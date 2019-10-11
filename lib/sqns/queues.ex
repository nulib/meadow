defmodule SQNS.Queues do
  @moduledoc false

  alias ExAws.SQS
  alias SQNS.Utils.Arn
  require Logger

  def list_queues(queues \\ [], start_token \\ nil) do
    with %{body: result} <- SQS.list_queues(start_token: start_token) |> ExAws.request!() do
      case Map.get(result, :next_token, "") do
        "" -> queues ++ result.queues
        token -> list_queues(queues ++ result.queues, token)
      end
    end
  end

  def list_queue_names do
    list_queues()
    |> Enum.map(fn queue_url ->
      queue_url |> URI.parse() |> Map.get(:path) |> Path.basename()
    end)
  end

  def create_queues(queues) do
    existing = list_queue_names()

    queues
    |> Enum.each(fn queue -> create_queue(queue, existing) end)
  end

  def create_queue(queue_name, existing) do
    case existing |> Enum.find(&(&1 == queue_name)) do
      nil ->
        Logger.info("Creating Queue: #{queue_name}")

        with %{body: %{queue_url: queue_url}} <-
               ExAws.SQS.create_queue(queue_name) |> ExAws.request!() do
          set_queue_policy(queue_url)
        end

      _ ->
        Logger.info("Queue #{queue_name} already exists")
        :noop
    end
  end

  def create_queue(queue_name), do: create_queue(queue_name, list_queue_names())

  def get_queue_arn(queue_url) do
    case queue_url
         |> ExAws.SQS.get_queue_attributes([:queue_arn])
         |> ExAws.request() do
      {:ok, %{body: %{attributes: %{queue_arn: result}}}} -> result
      {:error, _} -> nil
    end
  end

  def get_queue_url(queue_name) do
    case ExAws.SQS.get_queue_url(queue_name) |> ExAws.request() do
      {:ok, %{body: %{queue_url: result}}} -> result
      {:error, _} -> nil
    end
  end

  defp set_queue_policy(queue_url) do
    queue_arn = queue_url |> get_queue_arn()

    sns_glob_arn =
      queue_arn
      |> Arn.parse()
      |> Arn.update_service("sns")
      |> Arn.update_resource("*")
      |> Arn.to_string()

    queue_url
    |> ExAws.SQS.set_queue_attributes(
      policy:
        Jason.encode!(%{
          "Statement" => [
            %{
              "Action" => "SQS:SendMessage",
              "Condition" => %{
                "ArnLike" => %{
                  "aws:SourceArn" => sns_glob_arn
                }
              },
              "Effect" => "Allow",
              "Principal" => %{
                "AWS" => "*"
              },
              "Resource" => queue_arn,
              "Sid" => "sns-notifications-1"
            }
          ],
          "Version" => "2012-10-17"
        })
    )
    |> ExAws.request!()

    queue_url
  end
end
