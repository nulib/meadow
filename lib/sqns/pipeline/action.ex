defmodule SQNS.Pipeline.Action do
  @moduledoc ~S"""
  `SQNS.Pipeline.Action` wraps a [`Broadway SQS`](https://hexdocs.pm/broadway/amazon-sqs.html)
  processing pipeline to allow for the simple creation of multi-stage `SQS -> Broadway -> SNS`
  pipelines.

  ## Getting Started

  First, follow the [Create a SQS queue](https://hexdocs.pm/broadway/amazon-sqs.html#create-a-sqs-queue)
  and [Configure the project](https://hexdocs.pm/broadway/amazon-sqs.html#configure-the-project)
  sections of the Broadway Amazon SQS guide.

  Also make sure `config.exs` contains a valid [`ExAws`](https://hexdocs.pm/ex_aws/) configuration.

  ## Implement the processing callback

  This is where we depart from Broadway's default implementation. Pipeline.Action makes several
  opinionated assumptions about the AWS environment as well as the shape of the incoming
  message data.

  ### Processor

  `SQNS.Pipeline.Action` assumes that all message data is JSON, deserializing it before `process`
  and serializing it again on the way out. Instead of implementing `handle_message/3`,
  we're just going to implement our own `process/1`:

      defmodule MyApplication.MyPipeline do
        use Pipeline.Action

        def process(data) do
          data
          |> Map.get_and_update!(:value, fn n -> n * n end)
        end
      end

  By default, the queue and topic names are the same as the last segment of the using module
  name converted to a string. This can be overridden by passing a `:queue_name` option to
  `use`:

      defmodule MyApplication.MyPipeline do
        use Pipeline.Action, queue_name: "my-pipeline"
        ...
      end

  ### Batcher

  `SQNS.Pipeline.Action` sends processed data to an [AWS Simple Notification Service](https://aws.amazon.com/sns/)
  topic, allowing it to be dispatched to another queue (and into another `SQNS.Pipeline.Action`),
  an AWS Lambda, an arbitrary webhook, or even an email or SMS message.

  ## Configuration Options

  `SQNS.Pipeline.Action` attempts to use sane defaults, inheriting most of them from `Broadway` itself.
  However, several can be overriden in the application configuration.

  ### Options

  `SQNS.Pipeline.Action` is configured by passing options to `start_link`.
  Valid options are:

    * `:receive_interval` - Optional. The frequency with which the produer
      polls SQS for new messages. Default value is 5000.

    * `:producer_stages` - Optional. The number of producer stages to
      be created by Broadway. Analogous to Broadway's producer `:stages`
      option. Default value is 1.

    * `:processor_stages` - Optional. The number of processor stages to
      be created by Broadway. Analogous to Broadway's producer `:stages`
      option. Default value is 1.

    * `:max_demand` - Optional. Set the maximum demand of all processors
      stages. Analogous to Broadway's processor `:max_demand` option.
      Default value is 10.

    * `:min_demand` - Optional. Set the minimum demand of all processors
      stages. Analogous to Broadway's processor `:min_demand` option.
      Default value is 5.

    * `:batcher_stages` - Optional. The number of batcher stages to
      be created by Broadway. Analogous to Broadway's batcher `:stages`
      option. Default value is 1.

    * `:batch_size` - Optional. The size of generated batches. Analogous to
      Broadway's batcher `:batch_size` option. Default value is `100`.

    * `:batch_timeout` - Optional. The time, in milliseconds, that the
      batcher waits before flushing the list of messages. Analogous to
      Broadway's batcher `:batch_timeout` option. Default value is `1000`.
  """

  use Broadway
  alias Broadway.Message
  alias SQNS.Pipeline.Data
  require Logger

  @required_topics [:ok, :error]
  @callback process(data :: any(), attrs :: map()) ::
              {atom(), any(), map()} | {atom(), any()} | {atom()} | atom()

  defmacro __using__(use_opts) do
    use_opts =
      case use_opts[:queue_name] do
        nil ->
          queue =
            __CALLER__.module
            |> to_string()
            |> String.split(".")
            |> List.last()

          use_opts |> Keyword.put_new(:queue_name, queue)

        _ ->
          use_opts
      end

    quote location: :keep,
          bind_quoted: [queue: use_opts[:queue_name], module: __CALLER__.module] do
      alias SQNS.Pipeline
      require Logger

      @behaviour Pipeline.Action

      @doc false
      def child_spec(arg) do
        default = %{
          id: unquote(module),
          start: {__MODULE__, :start_link, [arg]},
          shutdown: :infinity
        }

        Supervisor.child_spec(default, [])
      end

      @doc false
      def start_link(opts) do
        Logger.debug("Starting #{__MODULE__}")

        Pipeline.Action.start_link(
          __MODULE__,
          opts |> Keyword.put_new(:queue_name, unquote(queue))
        )
      end

      @doc "Send a message directly to the Action's queue"
      def send_message(data, context \\ %{}) do
        unquote(queue)
        |> SQNS.Queues.get_queue_url()
        |> ExAws.SQS.send_message(
          %{
            "Message" => data,
            "MessageAttributes" =>
              context
              |> Enum.map(fn {name, value} ->
                {name, %{"Type" => "StringValue", "Value" => value}}
              end)
              |> Enum.into(%{})
          }
          |> Jason.encode!()
        )
        |> ExAws.request!()
      end
    end
  end

  @spec start_link(module :: module(), opts :: keyword()) :: {:ok, pid()}
  def start_link(module, opts) do
    opts = validate_config(opts)

    Broadway.start_link(
      __MODULE__,
      name: module,
      producers: [
        default: [
          module:
            {BroadwaySQS.Producer,
             queue_name: opts.queue_name, receive_interval: opts.receive_interval},
          stages: opts.producer_stages
        ]
      ],
      processors: [
        default: [
          stages: opts.processor_stages,
          min_demand: opts.min_demand,
          max_demand: opts.max_demand
        ]
      ],
      batchers: [
        sns: [
          stages: opts.batcher_stages,
          batch_size: opts.batch_size,
          batch_timeout: opts.batch_timeout
        ]
      ],
      context: %{
        module: module,
        queue_name: opts.queue_name,
        sns_topics: opts.sns_topics
      }
    )
  end

  @impl true
  def handle_message(_, message, %{module: module}) do
    message
    |> Message.put_batcher(:sns)
    |> Message.update_data(fn message_data ->
      with {data, attrs} <- Data.extract(message_data) do
        with old_action <- Logger.metadata()[:action] do
          try do
            Logger.metadata(action: module |> Module.split() |> List.last())

            case module.process(data, attrs) do
              {s, d, a} -> {s, d, a}
              {s, d} -> {s, d, attrs}
              {s} -> {s, data, attrs}
              s -> {s, data, attrs}
            end
            |> Data.update(module)
          after
            Logger.metadata(action: old_action)
          end
        end
      end
    end)
  end

  @impl true
  def handle_batch(:sns, messages, _, %{queue_name: queue_name}) do
    messages
    |> Enum.each(fn %Message{data: {_, data, attrs}} ->
      topic_arn = queue_name |> SQNS.Topics.get_topic_arn()

      data
      |> ExAws.SNS.publish(topic_arn: topic_arn, message_attributes: attrs)
      |> ExAws.request!()
    end)

    messages
  end

  defp ensure_sns_topics(context) do
    context
    |> Map.update!(:sns_topics, fn arns ->
      new_arns =
        Enum.reduce(@required_topics, arns, fn status, result ->
          status |> ensure_sns_topic(result, context)
        end)

      new_arns |> Enum.into(%{})
    end)
  end

  defp ensure_sns_topic(status, arns, context) do
    case arns[status] do
      t when is_binary(t) ->
        arns

      _ ->
        arns
        |> Keyword.put_new(
          status,
          (context[:queue_name]
           |> ExAws.SQS.get_queue_attributes([:queue_arn])
           |> ExAws.request!()
           |> Map.get(:body)
           |> Map.get(:attributes)
           |> Map.get(:queue_arn)
           |> String.replace(":sqs:", ":sns:")) <> "-" <> to_string(status)
        )
    end
  end

  defp validate_config(opts) do
    result =
      case opts |> Broadway.Options.validate(configuration_spec()) do
        {:error, err} ->
          raise %ArgumentError{message: err}

        {:ok, validated} ->
          validated
          |> Enum.into(%{})
          |> ensure_sns_topics()
      end

    case result do
      %{queue_name: queue_name} when not is_binary(queue_name) ->
        {:error, "expected :queue_name to be a binary, got: #{queue_name}"}

      _ ->
        result
    end
  end

  defp configuration_spec do
    [
      sns_topics: [type: :keyword_list, default: []],
      batch_size: [type: :pos_integer, default: 100],
      batch_timeout: [type: :pos_integer, default: 1000],
      batcher_stages: [type: :non_neg_integer, default: 1],
      max_demand: [type: :non_neg_integer, default: 10],
      min_demand: [type: :non_neg_integer, default: 5],
      processor_stages: [type: :non_neg_integer, default: System.schedulers_online() * 2],
      producer_stages: [type: :non_neg_integer, default: 1],
      receive_interval: [type: :non_neg_integer, default: 5000],
      queue_name: [required: true, type: :any]
    ]
  end
end
