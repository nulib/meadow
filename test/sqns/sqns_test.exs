defmodule SQNSTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias SQNS

  setup do
    existing_topics = SQNS.Topics.list_topics()
    existing_queues = SQNS.Queues.list_queues()
    existing_topic_names = SQNS.Topics.list_topic_names()
    existing_queue_names = SQNS.Queues.list_queue_names()
    existing_subscriptions = SQNS.Subscriptions.list_subscriptions()

    on_exit(fn ->
      (SQNS.Topics.list_topics() -- existing_topics)
      |> Enum.each(fn t -> ExAws.SNS.delete_topic(t) |> ExAws.request!() end)

      (SQNS.Queues.list_queues() -- existing_queues)
      |> Enum.each(fn q -> ExAws.SQS.delete_queue(q) |> ExAws.request!() end)
    end)

    created_queues = fn -> SQNS.Queues.list_queue_names() -- existing_queue_names end
    created_topics = fn -> SQNS.Topics.list_topic_names() -- existing_topic_names end
    created_subs = fn -> SQNS.Subscriptions.list_subscriptions() -- existing_subscriptions end

    {:ok,
     created_queues: created_queues, created_topics: created_topics, created_subs: created_subs}
  end

  describe "queues" do
    test "create missing queue" do
      assert(
        capture_log(fn ->
          assert(
            SQNS.Queues.create_queue("sqns_test_queue") ==
              "http://sqs.us-east-1.goaws.com:4100/100010001000/sqns_test_queue"
          )
        end) =~ "Creating Queue: sqns_test_queue"
      )
    end

    test "create existing queue" do
      SQNS.Queues.create_queue("sqns_test_queue")

      assert(
        capture_log(fn ->
          assert(SQNS.Queues.create_queue("sqns_test_queue") == :noop)
        end) =~ "Queue sqns_test_queue already exists"
      )
    end
  end

  describe "topics" do
    test "create missing topic" do
      assert(
        capture_log(fn ->
          assert(
            SQNS.Topics.create_topic("sqns_test_topic") ==
              "arn:aws:sns:us-east-1:100010001000:sqns_test_topic"
          )
        end) =~ "Creating Topic: sqns_test_topic"
      )
    end

    test "create existing topic" do
      SQNS.Topics.create_topic("sqns_test_topic")

      assert(
        capture_log(fn ->
          assert(SQNS.Topics.create_topic("sqns_test_topic") == :noop)
        end) =~ "Topic sqns_test_topic already exists"
      )
    end
  end

  describe "subscriptions" do
    setup do
      SQNS.Queues.create_queue("sqns_test_queue")
      SQNS.Topics.create_topic("sqns_test_topic")
      :ok
    end

    test "create missing subscription" do
      assert(
        capture_log(fn ->
          assert(
            SQNS.Subscriptions.create_subscription({"sqns_test_queue", "sqns_test_topic", nil}) ==
              {"arn:aws:sns:us-east-1:100010001000:sqns_test_topic",
               "arn:aws:sqs:us-east-1:100010001000:sqns_test_queue", %{}}
          )
        end) =~ "Creating Subscription: sqns_test_topic → sqns_test_queue"
      )
    end

    test "create existing subscription" do
      SQNS.Subscriptions.create_subscription({"sqns_test_queue", "sqns_test_topic", nil})

      assert(
        capture_log(fn ->
          assert(
            SQNS.Subscriptions.create_subscription({"sqns_test_queue", "sqns_test_topic", nil}) ==
              :noop
          )
        end) =~ "Subscription sqns_test_topic → sqns_test_queue already exists"
      )
    end
  end

  describe "specs" do
    test "create all queues, topics, and subscriptions based on a spec", %{
      created_topics: created_topics,
      created_queues: created_queues,
      created_subs: created_subs
    } do
      SQNS.setup([
        :a,
        b: [a: [status: :ok]],
        c: [:a, :b]
      ])

      expected_queues = ~w(a b c)
      expected_topics = ~w(a b c)

      expected_subscriptions = [
        {"a", "c", %{}},
        {"b", "c", %{}},
        {"a", "b", %{"status" => ["ok"]}}
      ]

      with actual_queues <- created_queues.() |> Enum.sort() do
        assert(actual_queues == expected_queues)
      end

      with actual_topics <- created_topics.() |> Enum.sort() do
        assert(actual_topics == expected_topics)
      end

      with actual_subscriptions <- created_subs.() do
        assert(
          expected_subscriptions
          |> Enum.all?(fn sub -> sub in actual_subscriptions end)
        )

        assert(actual_subscriptions -- expected_subscriptions == [])
      end
    end
  end
end
